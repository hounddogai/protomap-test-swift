import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a regional interaction rule.
    final class RegionalInteractionRuleView {
        var code: String
        var name: String
        var visitMinutesText: String
        var copayText: String
        var bed: String
        var updatedAt: String
        var approved: String
        var capacity: String
        var attempts: String
        var statusLabel: String

        init(code: String, name: String, visitMinutesText: String, copayText: String, bed: String, updatedAt: String, approved: String, capacity: String, attempts: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visitMinutesText = visitMinutesText
            self.copayText = copayText
            self.bed = bed
            self.updatedAt = updatedAt
            self.approved = approved
            self.capacity = capacity
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalInteractionRuleView(_ item: RegionalInteractionRule) -> RegionalInteractionRuleView {
        return RegionalInteractionRuleView(
            code: item.code,
            name: item.name,
            visitMinutesText: String(item.visitMinutes),
            copayText: String(format: "%.2f", item.copay),
            bed: item.bed,
            updatedAt: String(item.updatedAt),
            approved: "\(item.approved)",
            capacity: String(item.capacity),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalInteractionRuleViews(_ items: [RegionalInteractionRule]) -> [RegionalInteractionRuleView] {
        var views: [RegionalInteractionRuleView] = []
        for item in items {
            views.append(toRegionalInteractionRuleView(item))
        }
        return views
    }

    static func sumRegionalInteractionRuleView(_ view: RegionalInteractionRuleView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedVisitMinutes) + parsedCopay + Double(parsedUpdatedAt)
    }
}
