import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study allocation.
    final class StudyAllocationView {
        var code: String
        var name: String
        var summaryText: String
        var locale: String
        var archived: String
        var countryText: String
        var cost: String
        var statusLabel: String

        init(code: String, name: String, summaryText: String, locale: String, archived: String, countryText: String, cost: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.summaryText = summaryText
            self.locale = locale
            self.archived = archived
            self.countryText = countryText
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toStudyAllocationView(_ item: StudyAllocation) -> StudyAllocationView {
        return StudyAllocationView(
            code: item.code,
            name: item.name,
            summaryText: Kit.Text.truncate(item.summary, limit: 80),
            locale: item.locale,
            archived: "\(item.archived)",
            countryText: item.country,
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyAllocationViews(_ items: [StudyAllocation]) -> [StudyAllocationView] {
        var views: [StudyAllocationView] = []
        for item in items {
            views.append(toStudyAllocationView(item))
        }
        return views
    }

    static func sumStudyAllocationView(_ view: StudyAllocationView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
