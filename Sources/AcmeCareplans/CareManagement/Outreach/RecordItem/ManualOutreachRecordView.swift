import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a manual outreach record.
    final class ManualOutreachRecordView {
        var code: String
        var nameText: String
        var category: String
        var localeText: String
        var countryText: String
        var encounterID: String
        var bed: String
        var score: String
        var statusLabel: String

        init(code: String, nameText: String, category: String, localeText: String, countryText: String, encounterID: String, bed: String, score: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.category = category
            self.localeText = localeText
            self.countryText = countryText
            self.encounterID = encounterID
            self.bed = bed
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toManualOutreachRecordView(_ item: ManualOutreachRecord) -> ManualOutreachRecordView {
        return ManualOutreachRecordView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            category: item.category,
            localeText: item.locale,
            countryText: Kit.Text.truncate(item.country, limit: 40),
            encounterID: item.encounterID,
            bed: Kit.Text.truncate(item.bed, limit: 64),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualOutreachRecordViews(_ items: [ManualOutreachRecord]) -> [ManualOutreachRecordView] {
        var views: [ManualOutreachRecordView] = []
        for item in items {
            views.append(toManualOutreachRecordView(item))
        }
        return views
    }

    static func sumManualOutreachRecordView(_ view: ManualOutreachRecordView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
