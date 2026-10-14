import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a default care protocol record.
    final class DefaultCareProtocolRecordView {
        var code: String
        var title: String
        var sequence: String
        var procedureCode: String
        var unit: String
        var clinicianID: String
        var locale: String
        var graceDaysText: String
        var statusLabel: String

        init(code: String, title: String, sequence: String, procedureCode: String, unit: String, clinicianID: String, locale: String, graceDaysText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.procedureCode = procedureCode
            self.unit = unit
            self.clinicianID = clinicianID
            self.locale = locale
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCareProtocolRecordView(_ item: DefaultCareProtocolRecord) -> DefaultCareProtocolRecordView {
        return DefaultCareProtocolRecordView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            sequence: String(item.sequence),
            procedureCode: item.procedureCode,
            unit: item.unit,
            clinicianID: item.clinicianID,
            locale: Kit.Text.truncate(item.locale, limit: 40),
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCareProtocolRecordViews(_ items: [DefaultCareProtocolRecord]) -> [DefaultCareProtocolRecordView] {
        var views: [DefaultCareProtocolRecordView] = []
        for item in items {
            views.append(toDefaultCareProtocolRecordView(item))
        }
        return views
    }

    static func sumDefaultCareProtocolRecordView(_ view: DefaultCareProtocolRecordView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedSequence) + Double(parsedGraceDays)
    }
}
