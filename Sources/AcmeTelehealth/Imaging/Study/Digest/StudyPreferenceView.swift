import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study preference.
    final class StudyPreferenceView {
        var codeText: String
        var nameText: String
        var weight: String
        var limit: String
        var archived: String
        var payer: String
        var maximum: String
        var versionText: String
        var ratioText: String
        var budgetText: String
        var startsAt: String
        var statusLabel: String

        init(codeText: String, nameText: String, weight: String, limit: String, archived: String, payer: String, maximum: String, versionText: String, ratioText: String, budgetText: String, startsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.weight = weight
            self.limit = limit
            self.archived = archived
            self.payer = payer
            self.maximum = maximum
            self.versionText = versionText
            self.ratioText = ratioText
            self.budgetText = budgetText
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toStudyPreferenceView(_ item: StudyPreference) -> StudyPreferenceView {
        return StudyPreferenceView(
            codeText: item.code,
            nameText: item.name,
            weight: String(format: "%.2f", item.weight),
            limit: String(item.limit),
            archived: "\(item.archived)",
            payer: item.payer,
            maximum: String(format: "%.2f", item.maximum),
            versionText: String(item.version),
            ratioText: String(format: "%.2f", item.ratio),
            budgetText: String(format: "%.2f", item.budget),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyPreferenceViews(_ items: [StudyPreference]) -> [StudyPreferenceView] {
        var views: [StudyPreferenceView] = []
        for item in items {
            views.append(toStudyPreferenceView(item))
        }
        return views
    }

    static func sumStudyPreferenceView(_ view: StudyPreferenceView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedWeight + Double(parsedLimit) + parsedMaximum
    }
}
