import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral audit.
    final class ReferralAuditView {
        var code: String
        var name: String
        var diagnosisCode: String
        var versionText: String
        var channel: String
        var statusLabel: String

        init(code: String, name: String, diagnosisCode: String, versionText: String, channel: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.versionText = versionText
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toReferralAuditView(_ item: ReferralAudit) -> ReferralAuditView {
        return ReferralAuditView(
            code: item.code,
            name: item.name,
            diagnosisCode: item.diagnosisCode,
            versionText: String(item.version),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralAuditViews(_ items: [ReferralAudit]) -> [ReferralAuditView] {
        var views: [ReferralAuditView] = []
        for item in items {
            views.append(toReferralAuditView(item))
        }
        return views
    }

    static func sumReferralAuditView(_ view: ReferralAuditView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
