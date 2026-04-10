import Foundation
import Network

// Discovers Smart TVs on local network via SSDP + mDNS
class TVDiscoveryService: ObservableObject {
    @Published var devices: [TVDevice] = []
    @Published var isScanning = false

    private var ssdpSocket: NWConnection?
    private var mdnsBrowser: NWBrowser?
    private var discoveredIPs: Set<String> = []

    func startScan() {
        isScanning = true
        devices = []
        discoveredIPs = []
        startSSDPScan()
        startMDNSScan()
        // Also probe known ports on local subnet
        Task { await probeSubnet() }
    }

    func stopScan() {
        isScanning = false
        ssdpSocket?.cancel()
        mdnsBrowser?.cancel()
    }

    // MARK: - SSDP (Simple Service Discovery Protocol)

    private func startSSDPScan() {
        let ssdpQuery = """
        M-SEARCH * HTTP/1.1\r
        HOST: 239.255.255.250:1900\r
        MAN: "ssdp:discover"\r
        MX: 3\r
        ST: ssdp:all\r
        \r\n
        """

        let connection = NWConnection(
            to: .hostPort(host: "239.255.255.250", port: 1900),
            using: .udp
        )
        ssdpSocket = connection
        connection.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                connection.send(content: ssdpQuery.data(using: .utf8), completion: .idempotent)
                self?.receiveSSDPResponses(connection: connection)
            }
        }
        connection.start(queue: .global())
    }

    private func receiveSSDPResponses(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, error in
            guard let self, let data, error == nil else { return }
            if let response = String(data: data, encoding: .utf8) {
                self.parseSSDPResponse(response)
            }
            self.receiveSSDPResponses(connection: connection)
        }
    }

    private func parseSSDPResponse(_ response: String) {
        var ip = ""
        var brand = TVBrand.unknown

        for line in response.components(separatedBy: "\r\n") {
            let lower = line.lowercased()
            if lower.hasPrefix("location:") {
                let urlStr = line.replacingOccurrences(of: "location:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
                if let url = URL(string: urlStr), let host = url.host {
                    ip = host
                }
            }
            if lower.contains("samsung") { brand = .samsung }
            if lower.contains("lg") && lower.contains("tv") { brand = .lg }
            if lower.contains("sony") { brand = .sony }
            if lower.contains("roku") { brand = .roku }
            if lower.contains("philips") { brand = .philips }
        }

        guard !ip.isEmpty, !discoveredIPs.contains(ip) else { return }
        discoveredIPs.insert(ip)
        Task { await self.probeDevice(ip: ip, brand: brand) }
    }

    // MARK: - mDNS / Bonjour

    private func startMDNSScan() {
        let serviceTypes = [
            ("_samsungtv._tcp", TVBrand.samsung),
            ("_webostv._tcp", TVBrand.lg),
            ("_googlecast._tcp", TVBrand.androidTV),
            ("_apple-tvremote._tcp", TVBrand.appleTV),
            ("_roku._tcp", TVBrand.roku),
        ]

        for (serviceType, brand) in serviceTypes {
            let descriptor = NWBrowser.Descriptor.bonjour(type: serviceType, domain: "local.")
            let browser = NWBrowser(for: descriptor, using: .tcp)
            browser.browseResultsChangedHandler = { [weak self] results, _ in
                for result in results {
                    if case .service(let name, _, _, _) = result.endpoint {
                        self?.resolveBonjour(name: name, brand: brand)
                    }
                }
            }
            browser.start(queue: .global())
        }
    }

    private func resolveBonjour(name: String, brand: TVBrand) {
        // Resolve service name to IP via NWConnection
        let connection = NWConnection(to: .service(name: name, type: "_samsungtv._tcp", domain: "local.", interface: nil), using: .tcp)
        connection.stateUpdateHandler = { [weak self] state in
            if case .ready = state,
               case .hostPort(let host, _) = connection.currentPath?.remoteEndpoint {
                let ip = "\(host)"
                if !(self?.discoveredIPs.contains(ip) ?? true) {
                    self?.discoveredIPs.insert(ip)
                    Task { await self?.probeDevice(ip: ip, brand: brand) }
                }
                connection.cancel()
            }
        }
        connection.start(queue: .global())
    }

    // MARK: - Subnet probe

    private func probeSubnet() async {
        guard let localIP = getLocalIPAddress() else { return }
        let parts = localIP.components(separatedBy: ".")
        guard parts.count == 4, let base = parts.prefix(3).joined(separator: ".").nilIfEmpty else { return }

        await withTaskGroup(of: Void.self) { group in
            for i in 1...254 {
                let ip = "\(base).\(i)"
                guard !discoveredIPs.contains(ip) else { continue }
                group.addTask { [weak self] in
                    await self?.probeDevice(ip: ip, brand: .unknown)
                }
            }
        }
    }

    @MainActor
    private func probeDevice(ip: String, brand: TVBrand) async {
        // Try known TV ports
        let probes: [(Int, TVBrand)] = [
            (8001, .samsung), (8002, .samsung),
            (3000, .lg),
            (80, brand == .sony ? .sony : .unknown),
            (8060, .roku),
            (1925, .philips),
            (5555, brand == .fireTV ? .fireTV : .androidTV),
        ]

        for (port, probeBrand) in probes {
            if await checkPort(ip: ip, port: port) {
                let finalBrand = brand == .unknown ? probeBrand : brand
                let device = TVDevice(
                    id: "\(ip):\(port)",
                    name: "\(finalBrand.rawValue) TV",
                    brand: finalBrand,
                    ipAddress: ip,
                    port: port
                )
                if !devices.contains(where: { $0.ipAddress == ip }) {
                    devices.append(device)
                }
                return
            }
        }
    }

    private func checkPort(ip: String, port: Int) async -> Bool {
        await withCheckedContinuation { continuation in
            let connection = NWConnection(
                to: .hostPort(host: NWEndpoint.Host(ip), port: NWEndpoint.Port(integerLiteral: UInt16(port))),
                using: .tcp
            )
            var resumed = false
            let timer = DispatchSource.makeTimerSource()
            timer.schedule(deadline: .now() + 0.5)
            timer.setEventHandler {
                if !resumed { resumed = true; continuation.resume(returning: false) }
                connection.cancel()
                timer.cancel()
            }
            timer.resume()
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if !resumed { resumed = true; continuation.resume(returning: true) }
                    connection.cancel()
                    timer.cancel()
                case .failed:
                    if !resumed { resumed = true; continuation.resume(returning: false) }
                    timer.cancel()
                default: break
                }
            }
            connection.start(queue: .global())
        }
    }

    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }
        var ptr = ifaddr
        while let ifa = ptr?.pointee {
            let family = ifa.ifa_addr.pointee.sa_family
            if family == UInt8(AF_INET) {
                let name = String(cString: ifa.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(ifa.ifa_addr, socklen_t(ifa.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
            ptr = ifa.ifa_next
        }
        return address
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
