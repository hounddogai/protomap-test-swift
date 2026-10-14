import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession schedule.
    final class AccessionScheduleView {
        var code: String
        var title: String
        var description: String
        var revision: String
        var ratio: String
        var country: String
        var budgetText: String
        var score: String
        var updatedAt: String
        var attempts: String
        var versionText: String
        var statusLabel: String

        init(code: String, title: String, description: String, revision: String, ratio: String, country: String, budgetText: String, score: String, updatedAt: String, attempts: String, versionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.description = description
            self.revision = revision
            self.ratio = ratio
            self.country = country
            self.budgetText = budgetText
            self.score = score
            self.updatedAt = updatedAt
            self.attempts = attempts
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionScheduleView(_ item: AccessionSchedule) -> AccessionScheduleView {
        return AccessionScheduleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            description: item.description,
            revision: String(item.revision),
            ratio: String(format: "%.2f", item.ratio),
            country: item.country,
            budgetText: String(format: "%.2f", item.budget),
            score: String(format: "%.2f", item.score),
            updatedAt: String(item.updatedAt),
            attempts: String(item.attempts),
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionScheduleViews(_ items: [AccessionSchedule]) -> [AccessionScheduleView] {
        var views: [AccessionScheduleView] = []
        for item in items {
            views.append(toAccessionScheduleView(item))
        }
        return views
    }

    static func sumAccessionScheduleView(_ view: AccessionScheduleView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedRevision) + parsedRatio + parsedBudget
    }
}
