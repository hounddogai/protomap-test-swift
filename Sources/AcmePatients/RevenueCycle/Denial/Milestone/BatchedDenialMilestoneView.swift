import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched denial milestone.
    final class BatchedDenialMilestoneView {
        var code: String
        var name: String
        var quantityText: String
        var sequenceText: String
        var timezoneText: String
        var locale: String
        var regionText: String
        var cost: String
        var pinned: String
        var approved: String
        var statusLabel: String

        init(code: String, name: String, quantityText: String, sequenceText: String, timezoneText: String, locale: String, regionText: String, cost: String, pinned: String, approved: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.quantityText = quantityText
            self.sequenceText = sequenceText
            self.timezoneText = timezoneText
            self.locale = locale
            self.regionText = regionText
            self.cost = cost
            self.pinned = pinned
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedDenialMilestoneView(_ item: BatchedDenialMilestone) -> BatchedDenialMilestoneView {
        return BatchedDenialMilestoneView(
            code: item.code,
            name: item.name,
            quantityText: String(item.quantity),
            sequenceText: String(item.sequence),
            timezoneText: item.timezone,
            locale: item.locale,
            regionText: item.region,
            cost: String(format: "%.2f", item.cost),
            pinned: "\(item.pinned)",
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedDenialMilestoneViews(_ items: [BatchedDenialMilestone]) -> [BatchedDenialMilestoneView] {
        var views: [BatchedDenialMilestoneView] = []
        for item in items {
            views.append(toBatchedDenialMilestoneView(item))
        }
        return views
    }

    static func sumBatchedDenialMilestoneView(_ view: BatchedDenialMilestoneView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedQuantity) + Double(parsedSequence) + parsedCost
    }
}
