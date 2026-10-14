import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a adaptive care gap notice.
    final class AdaptiveCareGapNoticeView {
        var code: String
        var name: String
        var score: String
        var source: String
        var specialtyText: String
        var approvedText: String
        var payer: String
        var patientRefText: String
        var ratio: String
        var externalRefText: String
        var statusLabel: String

        init(code: String, name: String, score: String, source: String, specialtyText: String, approvedText: String, payer: String, patientRefText: String, ratio: String, externalRefText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.score = score
            self.source = source
            self.specialtyText = specialtyText
            self.approvedText = approvedText
            self.payer = payer
            self.patientRefText = patientRefText
            self.ratio = ratio
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCareGapNoticeView(_ item: AdaptiveCareGapNotice) -> AdaptiveCareGapNoticeView {
        return AdaptiveCareGapNoticeView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            score: String(format: "%.2f", item.score),
            source: item.source,
            specialtyText: item.specialty,
            approvedText: "\(item.approved)",
            payer: item.payer,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 80),
            ratio: String(format: "%.2f", item.ratio),
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCareGapNoticeViews(_ items: [AdaptiveCareGapNotice]) -> [AdaptiveCareGapNoticeView] {
        var views: [AdaptiveCareGapNoticeView] = []
        for item in items {
            views.append(toAdaptiveCareGapNoticeView(item))
        }
        return views
    }

    static func sumAdaptiveCareGapNoticeView(_ view: AdaptiveCareGapNoticeView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedScore + parsedRatio
    }
}
