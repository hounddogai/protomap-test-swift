import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback accession notice.
    final class FallbackAccessionNoticeView {
        var code: String
        var name: String
        var locale: String
        var notes: String
        var patientRefText: String
        var approvedText: String
        var score: String
        var statusLabel: String

        init(code: String, name: String, locale: String, notes: String, patientRefText: String, approvedText: String, score: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.locale = locale
            self.notes = notes
            self.patientRefText = patientRefText
            self.approvedText = approvedText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackAccessionNoticeView(_ item: FallbackAccessionNotice) -> FallbackAccessionNoticeView {
        return FallbackAccessionNoticeView(
            code: item.code,
            name: item.name,
            locale: Kit.Text.truncate(item.locale, limit: 120),
            notes: item.notes,
            patientRefText: item.patientRef,
            approvedText: "\(item.approved)",
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackAccessionNoticeViews(_ items: [FallbackAccessionNotice]) -> [FallbackAccessionNoticeView] {
        var views: [FallbackAccessionNoticeView] = []
        for item in items {
            views.append(toFallbackAccessionNoticeView(item))
        }
        return views
    }

    static func sumFallbackAccessionNoticeView(_ view: FallbackAccessionNoticeView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
