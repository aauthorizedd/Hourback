import SwiftUI

struct HourBackMark: View {
    var side: CGFloat = 22

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.primary)
            Text("H")
                .font(.custom("TimesNewRomanPSMT", size: side * 0.62))
                .foregroundStyle(Color(.systemBackground))
        }
        .frame(width: side, height: side)
        .accessibilityLabel("HourBack")
    }
}

struct BlockMark: View {
    var isOn: Bool
    private let side: CGFloat = 200

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.primary, lineWidth: 1)
                .opacity(isOn ? 0 : 1)
            Rectangle()
                .fill(Color.primary)
                .opacity(isOn ? 1 : 0)
        }
        .frame(width: side, height: side)
        .animation(.easeInOut(duration: 0.3), value: isOn)
        .accessibilityLabel(isOn ? "Blocking" : "Not blocking")
    }
}

struct OutlineButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.body)
                .foregroundStyle(Color.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .overlay(
                    Rectangle()
                        .stroke(Color.primary, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: 1)
    }
}

struct HourBackScreen<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}
