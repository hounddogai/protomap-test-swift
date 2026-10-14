import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending network threshold.
    final class PendingNetworkThresholdView {
        var code: String
        var label: String
        var weightText: String
        var batchSize: String
        var revision: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, label: String, weightText: String, batchSize: String, revision: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.weightText = weightText
            self.batchSize = batchSize
            self.revision = revision
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toPendingNetworkThresholdView(_ item: PendingNetworkThreshold) -> PendingNetworkThresholdView {
        return PendingNetworkThresholdView(
            code: item.code,
            label: item.label,
            weightText: String(format: "%.2f", item.weight),
            batchSize: String(item.batchSize),
            revision: String(item.revision),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingNetworkThresholdViews(_ items: [PendingNetworkThreshold]) -> [PendingNetworkThresholdView] {
        var views: [PendingNetworkThresholdView] = []
        for item in items {
            views.append(toPendingNetworkThresholdView(item))
        }
        return views
    }

    static func sumPendingNetworkThresholdView(_ view: PendingNetworkThresholdView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedWeight + Double(parsedBatchSize) + Double(parsedRevision)
    }
}
