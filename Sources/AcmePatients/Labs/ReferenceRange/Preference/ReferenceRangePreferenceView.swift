import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range preference.
    final class ReferenceRangePreferenceView {
        var code: String
        var title: String
        var localeText: String
        var archivedText: String
        var procedureCode: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, localeText: String, archivedText: String, procedureCode: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.localeText = localeText
            self.archivedText = archivedText
            self.procedureCode = procedureCode
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangePreferenceView(_ item: ReferenceRangePreference) -> ReferenceRangePreferenceView {
        return ReferenceRangePreferenceView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            localeText: Kit.Text.truncate(item.locale, limit: 120),
            archivedText: "\(item.archived)",
            procedureCode: item.procedureCode,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangePreferenceViews(_ items: [ReferenceRangePreference]) -> [ReferenceRangePreferenceView] {
        var views: [ReferenceRangePreferenceView] = []
        for item in items {
            views.append(toReferenceRangePreferenceView(item))
        }
        return views
    }

    static func sumReferenceRangePreferenceView(_ view: ReferenceRangePreferenceView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
