import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending network snapshot.
    final class PendingNetworkSnapshotView {
        var code: String
        var title: String
        var ceiling: String
        var capacity: String
        var channelText: String
        var statusLabel: String

        init(code: String, title: String, ceiling: String, capacity: String, channelText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.capacity = capacity
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingNetworkSnapshotView(_ item: PendingNetworkSnapshot) -> PendingNetworkSnapshotView {
        return PendingNetworkSnapshotView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 64),
            ceiling: String(format: "%.2f", item.ceiling),
            capacity: String(item.capacity),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingNetworkSnapshotViews(_ items: [PendingNetworkSnapshot]) -> [PendingNetworkSnapshotView] {
        var views: [PendingNetworkSnapshotView] = []
        for item in items {
            views.append(toPendingNetworkSnapshotView(item))
        }
        return views
    }

    static func sumPendingNetworkSnapshotView(_ view: PendingNetworkSnapshotView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedCeiling + Double(parsedCapacity)
    }
}
