import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a fallback priority group.
    final class FallbackPriorityGroupView {
        var codeText: String
        var label: String
        var bedText: String
        var categoryText: String
        var limit: String
        var attempts: String
        var acuity: String
        var threshold: String
        var maximum: String
        var costText: String
        var statusLabel: String

        init(codeText: String, label: String, bedText: String, categoryText: String, limit: String, attempts: String, acuity: String, threshold: String, maximum: String, costText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.bedText = bedText
            self.categoryText = categoryText
            self.limit = limit
            self.attempts = attempts
            self.acuity = acuity
            self.threshold = threshold
            self.maximum = maximum
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackPriorityGroupView(_ item: FallbackPriorityGroup) -> FallbackPriorityGroupView {
        return FallbackPriorityGroupView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            bedText: item.bed,
            categoryText: item.category,
            limit: String(item.limit),
            attempts: String(item.attempts),
            acuity: String(item.acuity),
            threshold: String(format: "%.2f", item.threshold),
            maximum: String(format: "%.2f", item.maximum),
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackPriorityGroupViews(_ items: [FallbackPriorityGroup]) -> [FallbackPriorityGroupView] {
        var views: [FallbackPriorityGroupView] = []
        for item in items {
            views.append(toFallbackPriorityGroupView(item))
        }
        return views
    }

    static func sumFallbackPriorityGroupView(_ view: FallbackPriorityGroupView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedLimit) + Double(parsedAttempts) + Double(parsedAcuity)
    }
}
