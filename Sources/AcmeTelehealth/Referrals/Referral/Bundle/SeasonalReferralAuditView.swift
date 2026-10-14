import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal referral audit.
    final class SeasonalReferralAuditView {
        var code: String
        var label: String
        var checksum: String
        var unit: String
        var patientRefText: String
        var name: String
        var score: String
        var statusLabel: String

        init(code: String, label: String, checksum: String, unit: String, patientRefText: String, name: String, score: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.unit = unit
            self.patientRefText = patientRefText
            self.name = name
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalReferralAuditView(_ item: SeasonalReferralAudit) -> SeasonalReferralAuditView {
        return SeasonalReferralAuditView(
            code: item.code,
            label: item.label,
            checksum: item.checksum,
            unit: Kit.Text.truncate(item.unit, limit: 80),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 120),
            name: item.name,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalReferralAuditViews(_ items: [SeasonalReferralAudit]) -> [SeasonalReferralAuditView] {
        var views: [SeasonalReferralAuditView] = []
        for item in items {
            views.append(toSeasonalReferralAuditView(item))
        }
        return views
    }

    static func sumSeasonalReferralAuditView(_ view: SeasonalReferralAuditView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
