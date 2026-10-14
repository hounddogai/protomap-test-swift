import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession template.
    final class AccessionTemplateView {
        var code: String
        var title: String
        var active: String
        var score: String
        var updatedAtText: String
        var limit: String
        var durationMinutes: String
        var contactEmail: String
        var priority: String
        var minimum: String
        var cost: String
        var statusLabel: String

        init(code: String, title: String, active: String, score: String, updatedAtText: String, limit: String, durationMinutes: String, contactEmail: String, priority: String, minimum: String, cost: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.active = active
            self.score = score
            self.updatedAtText = updatedAtText
            self.limit = limit
            self.durationMinutes = durationMinutes
            self.contactEmail = contactEmail
            self.priority = priority
            self.minimum = minimum
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionTemplateView(_ item: AccessionTemplate) -> AccessionTemplateView {
        return AccessionTemplateView(
            code: item.code,
            title: item.title,
            active: "\(item.active)",
            score: String(format: "%.2f", item.score),
            updatedAtText: String(item.updatedAt),
            limit: String(item.limit),
            durationMinutes: String(item.durationMinutes),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 120),
            priority: String(item.priority),
            minimum: String(format: "%.2f", item.minimum),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionTemplateViews(_ items: [AccessionTemplate]) -> [AccessionTemplateView] {
        var views: [AccessionTemplateView] = []
        for item in items {
            views.append(toAccessionTemplateView(item))
        }
        return views
    }

    static func sumAccessionTemplateView(_ view: AccessionTemplateView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedScore + Double(parsedUpdatedAt) + Double(parsedLimit)
    }
}
