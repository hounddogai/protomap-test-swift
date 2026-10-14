import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling substitution claim.
    final class RollingSubstitutionClaimView {
        var code: String
        var title: String
        var acuity: String
        var startsAt: String
        var diagnosisCode: String
        var copayText: String
        var statusLabel: String

        init(code: String, title: String, acuity: String, startsAt: String, diagnosisCode: String, copayText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.startsAt = startsAt
            self.diagnosisCode = diagnosisCode
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingSubstitutionClaimView(_ item: RollingSubstitutionClaim) -> RollingSubstitutionClaimView {
        return RollingSubstitutionClaimView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 64),
            acuity: String(item.acuity),
            startsAt: String(item.startsAt),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingSubstitutionClaimViews(_ items: [RollingSubstitutionClaim]) -> [RollingSubstitutionClaimView] {
        var views: [RollingSubstitutionClaimView] = []
        for item in items {
            views.append(toRollingSubstitutionClaimView(item))
        }
        return views
    }

    static func sumRollingSubstitutionClaimView(_ view: RollingSubstitutionClaimView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedAcuity) + Double(parsedStartsAt) + parsedCopay
    }
}
