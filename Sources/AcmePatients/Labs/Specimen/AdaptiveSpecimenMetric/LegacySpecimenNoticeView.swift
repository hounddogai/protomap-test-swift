import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy specimen notice.
    final class LegacySpecimenNoticeView {
        var codeText: String
        var title: String
        var attemptsText: String
        var summary: String
        var diagnosisCode: String
        var category: String
        var sequence: String
        var unitText: String
        var currency: String
        var statusLabel: String

        init(codeText: String, title: String, attemptsText: String, summary: String, diagnosisCode: String, category: String, sequence: String, unitText: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.attemptsText = attemptsText
            self.summary = summary
            self.diagnosisCode = diagnosisCode
            self.category = category
            self.sequence = sequence
            self.unitText = unitText
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toLegacySpecimenNoticeView(_ item: LegacySpecimenNotice) -> LegacySpecimenNoticeView {
        return LegacySpecimenNoticeView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            attemptsText: String(item.attempts),
            summary: item.summary,
            diagnosisCode: item.diagnosisCode,
            category: item.category,
            sequence: String(item.sequence),
            unitText: Kit.Text.truncate(item.unit, limit: 40),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacySpecimenNoticeViews(_ items: [LegacySpecimenNotice]) -> [LegacySpecimenNoticeView] {
        var views: [LegacySpecimenNoticeView] = []
        for item in items {
            views.append(toLegacySpecimenNoticeView(item))
        }
        return views
    }

    static func sumLegacySpecimenNoticeView(_ view: LegacySpecimenNoticeView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedAttempts) + Double(parsedSequence)
    }
}
