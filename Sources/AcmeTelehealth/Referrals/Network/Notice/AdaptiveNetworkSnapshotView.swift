import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a adaptive network snapshot.
    final class AdaptiveNetworkSnapshotView {
        var code: String
        var label: String
        var batchSize: String
        var discountText: String
        var endsAt: String
        var patientRef: String
        var statusLabel: String

        init(code: String, label: String, batchSize: String, discountText: String, endsAt: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.discountText = discountText
            self.endsAt = endsAt
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveNetworkSnapshotView(_ item: AdaptiveNetworkSnapshot) -> AdaptiveNetworkSnapshotView {
        return AdaptiveNetworkSnapshotView(
            code: item.code,
            label: item.label,
            batchSize: String(item.batchSize),
            discountText: String(format: "%.2f", item.discount),
            endsAt: String(item.endsAt),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveNetworkSnapshotViews(_ items: [AdaptiveNetworkSnapshot]) -> [AdaptiveNetworkSnapshotView] {
        var views: [AdaptiveNetworkSnapshotView] = []
        for item in items {
            views.append(toAdaptiveNetworkSnapshotView(item))
        }
        return views
    }

    static func sumAdaptiveNetworkSnapshotView(_ view: AdaptiveNetworkSnapshotView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedBatchSize) + parsedDiscount + Double(parsedEndsAt)
    }
}
