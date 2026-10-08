import SwiftUI

struct TagsView: View {
    var model: AppModel

    var body: some View {
        HourBackScreen {
            if model.tagHashes.isEmpty {
                Text("No tags paired.")
                    .font(Typography.body)
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(model.tagHashes.enumerated()), id: \.element) { index, hash in
                    HStack {
                        Text("Tag \(index + 1)")
                        Spacer()
                        Button("Remove") { model.removeTag(hash: hash) }
                    }
                    .font(Typography.body)
                    .foregroundStyle(Color.primary)
                    .padding(.vertical, 14)
                    Hairline()
                }
            }

            if model.isBlocking {
                Text("Turn blocking off before removing a tag.")
                    .font(Typography.small)
            }

            OutlineButton(title: "Pair a tag") {
                Task { await model.pairTag() }
            }

            if model.tagHashes.count >= AppConfig.maxPairedTags {
                Text("You can pair up to 3 tags.")
                    .font(Typography.small)
            }
        }
        .navigationTitle("Tags")
    }
}
