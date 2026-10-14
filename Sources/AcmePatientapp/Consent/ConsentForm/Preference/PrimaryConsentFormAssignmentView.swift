import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary consent form assignment.
    final class PrimaryConsentFormAssignmentView {
        var code: String
        var name: String
        var costText: String
        var timezone: String
        var minimum: String
        var country: String
        var budgetText: String
        var priorityText: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, name: String, costText: String, timezone: String, minimum: String, country: String, budgetText: String, priorityText: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.costText = costText
            self.timezone = timezone
            self.minimum = minimum
            self.country = country
            self.budgetText = budgetText
            self.priorityText = priorityText
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryConsentFormAssignmentView(_ item: PrimaryConsentFormAssignment) -> PrimaryConsentFormAssignmentView {
        return PrimaryConsentFormAssignmentView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            costText: String(format: "%.2f", item.cost),
            timezone: item.timezone,
            minimum: String(format: "%.2f", item.minimum),
            country: item.country,
            budgetText: String(format: "%.2f", item.budget),
            priorityText: String(item.priority),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryConsentFormAssignmentViews(_ items: [PrimaryConsentFormAssignment]) -> [PrimaryConsentFormAssignmentView] {
        var views: [PrimaryConsentFormAssignmentView] = []
        for item in items {
            views.append(toPrimaryConsentFormAssignmentView(item))
        }
        return views
    }

    static func sumPrimaryConsentFormAssignmentView(_ view: PrimaryConsentFormAssignmentView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedCost + parsedMinimum + parsedBudget
    }
}
