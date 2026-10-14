import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a capped cleaning agreement.
    final class CappedCleaningAgreementView {
        var code: String
        var label: String
        var title: String
        var timezone: String
        var batchSize: String
        var allergyText: String
        var clinicianID: String
        var archived: String
        var startsAt: String
        var categoryText: String
        var statusLabel: String

        init(code: String, label: String, title: String, timezone: String, batchSize: String, allergyText: String, clinicianID: String, archived: String, startsAt: String, categoryText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.title = title
            self.timezone = timezone
            self.batchSize = batchSize
            self.allergyText = allergyText
            self.clinicianID = clinicianID
            self.archived = archived
            self.startsAt = startsAt
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedCleaningAgreementView(_ item: CappedCleaningAgreement) -> CappedCleaningAgreementView {
        return CappedCleaningAgreementView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            title: item.title,
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            batchSize: String(item.batchSize),
            allergyText: item.allergy,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 80),
            archived: "\(item.archived)",
            startsAt: String(item.startsAt),
            categoryText: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedCleaningAgreementViews(_ items: [CappedCleaningAgreement]) -> [CappedCleaningAgreementView] {
        var views: [CappedCleaningAgreementView] = []
        for item in items {
            views.append(toCappedCleaningAgreementView(item))
        }
        return views
    }

    static func sumCappedCleaningAgreementView(_ view: CappedCleaningAgreementView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedStartsAt)
    }
}
