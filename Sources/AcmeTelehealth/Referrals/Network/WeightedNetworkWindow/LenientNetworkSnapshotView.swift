import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a lenient network snapshot.
    final class LenientNetworkSnapshotView {
        var codeText: String
        var name: String
        var payerText: String
        var marginText: String
        var graceDaysText: String
        var capacity: String
        var archived: String
        var statusLabel: String

        init(codeText: String, name: String, payerText: String, marginText: String, graceDaysText: String, capacity: String, archived: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.payerText = payerText
            self.marginText = marginText
            self.graceDaysText = graceDaysText
            self.capacity = capacity
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toLenientNetworkSnapshotView(_ item: LenientNetworkSnapshot) -> LenientNetworkSnapshotView {
        return LenientNetworkSnapshotView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            payerText: item.payer,
            marginText: String(format: "%.2f", item.margin),
            graceDaysText: String(item.graceDays),
            capacity: String(item.capacity),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientNetworkSnapshotViews(_ items: [LenientNetworkSnapshot]) -> [LenientNetworkSnapshotView] {
        var views: [LenientNetworkSnapshotView] = []
        for item in items {
            views.append(toLenientNetworkSnapshotView(item))
        }
        return views
    }

    static func sumLenientNetworkSnapshotView(_ view: LenientNetworkSnapshotView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedMargin + Double(parsedGraceDays) + Double(parsedCapacity)
    }
}
