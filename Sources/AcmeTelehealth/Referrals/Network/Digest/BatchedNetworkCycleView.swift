import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched network cycle.
    final class BatchedNetworkCycleView {
        var codeText: String
        var label: String
        var patientRef: String
        var source: String
        var categoryText: String
        var pinned: String
        var regionText: String
        var amount: String
        var statusLabel: String

        init(codeText: String, label: String, patientRef: String, source: String, categoryText: String, pinned: String, regionText: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.patientRef = patientRef
            self.source = source
            self.categoryText = categoryText
            self.pinned = pinned
            self.regionText = regionText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedNetworkCycleView(_ item: BatchedNetworkCycle) -> BatchedNetworkCycleView {
        return BatchedNetworkCycleView(
            codeText: item.code,
            label: item.label,
            patientRef: item.patientRef,
            source: Kit.Text.truncate(item.source, limit: 80),
            categoryText: item.category,
            pinned: "\(item.pinned)",
            regionText: Kit.Text.truncate(item.region, limit: 80),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedNetworkCycleViews(_ items: [BatchedNetworkCycle]) -> [BatchedNetworkCycleView] {
        var views: [BatchedNetworkCycleView] = []
        for item in items {
            views.append(toBatchedNetworkCycleView(item))
        }
        return views
    }

    static func sumBatchedNetworkCycleView(_ view: BatchedNetworkCycleView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
