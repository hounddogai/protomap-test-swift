import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal summary.
    final class GoalSummaryView {
        var codeText: String
        var title: String
        var capacity: String
        var contactEmail: String
        var minimum: String
        var country: String
        var attemptsText: String
        var payer: String
        var endsAt: String
        var statusLabel: String

        init(codeText: String, title: String, capacity: String, contactEmail: String, minimum: String, country: String, attemptsText: String, payer: String, endsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.capacity = capacity
            self.contactEmail = contactEmail
            self.minimum = minimum
            self.country = country
            self.attemptsText = attemptsText
            self.payer = payer
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toGoalSummaryView(_ item: GoalSummary) -> GoalSummaryView {
        return GoalSummaryView(
            codeText: item.code,
            title: item.title,
            capacity: String(item.capacity),
            contactEmail: item.contactEmail,
            minimum: String(format: "%.2f", item.minimum),
            country: item.country,
            attemptsText: String(item.attempts),
            payer: item.payer,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalSummaryViews(_ items: [GoalSummary]) -> [GoalSummaryView] {
        var views: [GoalSummaryView] = []
        for item in items {
            views.append(toGoalSummaryView(item))
        }
        return views
    }

    static func sumGoalSummaryView(_ view: GoalSummaryView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedCapacity) + parsedMinimum + Double(parsedAttempts)
    }
}
