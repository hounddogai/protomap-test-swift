import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a strict care protocol record.
    final class StrictCareProtocolRecordView {
        var code: String
        var title: String
        var quantity: String
        var approvedText: String
        var locale: String
        var contactEmail: String
        var graceDays: String
        var specialtyText: String
        var updatedAtText: String
        var bed: String
        var attempts: String
        var statusLabel: String

        init(code: String, title: String, quantity: String, approvedText: String, locale: String, contactEmail: String, graceDays: String, specialtyText: String, updatedAtText: String, bed: String, attempts: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.approvedText = approvedText
            self.locale = locale
            self.contactEmail = contactEmail
            self.graceDays = graceDays
            self.specialtyText = specialtyText
            self.updatedAtText = updatedAtText
            self.bed = bed
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toStrictCareProtocolRecordView(_ item: StrictCareProtocolRecord) -> StrictCareProtocolRecordView {
        return StrictCareProtocolRecordView(
            code: item.code,
            title: item.title,
            quantity: String(item.quantity),
            approvedText: "\(item.approved)",
            locale: Kit.Text.truncate(item.locale, limit: 40),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 64),
            graceDays: String(item.graceDays),
            specialtyText: item.specialty,
            updatedAtText: String(item.updatedAt),
            bed: item.bed,
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictCareProtocolRecordViews(_ items: [StrictCareProtocolRecord]) -> [StrictCareProtocolRecordView] {
        var views: [StrictCareProtocolRecordView] = []
        for item in items {
            views.append(toStrictCareProtocolRecordView(item))
        }
        return views
    }

    static func sumStrictCareProtocolRecordView(_ view: StrictCareProtocolRecordView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedQuantity) + Double(parsedGraceDays) + Double(parsedUpdatedAt)
    }
}
