import SwiftUI

// On-screen keyboard that sends text to the TV
struct TVKeyboardView: View {
    let onSendText: (String) -> Void
    @State private var inputText = ""
    @Environment(\.dismiss) private var dismiss

    private let rows: [[String]] = [
        ["q","w","e","r","t","y","u","i","o","p"],
        ["a","s","d","f","g","h","j","k","l"],
        ["⇧","z","x","c","v","b","n","m","⌫"],
        ["123","🌐"," ","↩"]
    ]
    private let numberRows: [[String]] = [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["-","/",":",";","(",")",  "$","&","@","\""],
        ["#+=",".",",","?","!","'","⌫"],
        ["ABC","🌐"," ","↩"]
    ]
    @State private var isShifted = false
    @State private var showNumbers = false

    var currentRows: [[String]] { showNumbers ? numberRows : rows }

    var body: some View {
        VStack(spacing: 0) {
            // Text preview
            HStack {
                TextField("Type here...", text: $inputText)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)

                Button {
                    onSendText(inputText)
                    inputText = ""
                    dismiss()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Keyboard rows
            VStack(spacing: 8) {
                ForEach(Array(currentRows.enumerated()), id: \.offset) { _, row in
                    keyboardRow(row)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 16)
        }
        .background(Color(hex: "1C1C2E"))
    }

    @ViewBuilder
    private func keyboardRow(_ keys: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(keys, id: \.self) { key in
                keyButton(key)
            }
        }
    }

    @ViewBuilder
    private func keyButton(_ key: String) -> some View {
        let displayKey = (!showNumbers && isShifted && key.count == 1) ? key.uppercased() : key
        let isSpecial = ["⇧","⌫","↩","123","ABC","🌐","#+="].contains(key)
        let isSpace = key == " "

        Button {
            handleKey(key)
        } label: {
            Group {
                if key == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 15, weight: .medium))
                } else if key == "↩" {
                    Image(systemName: "return")
                        .font(.system(size: 15, weight: .medium))
                } else if key == " " {
                    Text("space")
                        .font(.system(size: 13))
                } else {
                    Text(displayKey)
                        .font(.system(size: isSpecial ? 13 : 16, weight: isSpecial ? .medium : .regular))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: isSpace ? .infinity : nil)
            .frame(width: isSpace ? nil : (isSpecial ? 44 : 36), height: 42)
            .background(isSpecial ? Color.white.opacity(0.15) : Color.white.opacity(0.25))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func handleKey(_ key: String) {
        switch key {
        case "⌫":
            if !inputText.isEmpty { inputText.removeLast() }
            onSendText("\u{08}") // backspace
        case "↩":
            onSendText(inputText)
            inputText = ""
            dismiss()
        case "⇧":
            isShifted.toggle()
        case "123":
            showNumbers = true
        case "ABC":
            showNumbers = false
        case "🌐":
            break // language switch - noop
        case "#+=":
            break
        default:
            let char = (!showNumbers && isShifted) ? key.uppercased() : key
            inputText.append(contentsOf: char)
            onSendText(char)
            if isShifted { isShifted = false }
        }
    }
}
