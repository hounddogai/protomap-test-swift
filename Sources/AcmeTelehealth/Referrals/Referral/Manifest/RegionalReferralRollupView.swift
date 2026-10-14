import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional referral rollup.
    final class RegionalReferralRollupView {
        var codeText: String
        var title: String
        var patientRef: String
        var notesText: String
        var countryText: String
        var unitText: String
        var procedureCode: String
        var updatedAt: String
        var segment: String
        var statusLabel: String

        init(codeText: String, title: String, patientRef: String, notesText: String, countryText: String, unitText: String, procedureCode: String, updatedAt: String, segment: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.patientRef = patientRef
            self.notesText = notesText
            self.countryText = countryText
            self.unitText = unitText
            self.procedureCode = procedureCode
            self.updatedAt = updatedAt
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalReferralRollupView(_ item: RegionalReferralRollup) -> RegionalReferralRollupView {
        return RegionalReferralRollupView(
            codeText: item.code,
            title: item.title,
            patientRef: item.patientRef,
            notesText: Kit.Text.truncate(item.notes, limit: 80),
            countryText: item.country,
            unitText: item.unit,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            updatedAt: String(item.updatedAt),
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalReferralRollupViews(_ items: [RegionalReferralRollup]) -> [RegionalReferralRollupView] {
        var views: [RegionalReferralRollupView] = []
        for item in items {
            views.append(toRegionalReferralRollupView(item))
        }
        return views
    }

    static func sumRegionalReferralRollupView(_ view: RegionalReferralRollupView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
