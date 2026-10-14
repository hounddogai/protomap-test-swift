import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional skill mix quota.
    final class RegionalSkillMixQuotaView {
        var code: String
        var name: String
        var diagnosisCode: String
        var copayText: String
        var updatedAt: String
        var countryText: String
        var discount: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, name: String, diagnosisCode: String, copayText: String, updatedAt: String, countryText: String, discount: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.copayText = copayText
            self.updatedAt = updatedAt
            self.countryText = countryText
            self.discount = discount
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalSkillMixQuotaView(_ item: RegionalSkillMixQuota) -> RegionalSkillMixQuotaView {
        return RegionalSkillMixQuotaView(
            code: item.code,
            name: item.name,
            diagnosisCode: item.diagnosisCode,
            copayText: String(format: "%.2f", item.copay),
            updatedAt: String(item.updatedAt),
            countryText: item.country,
            discount: String(format: "%.2f", item.discount),
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalSkillMixQuotaViews(_ items: [RegionalSkillMixQuota]) -> [RegionalSkillMixQuotaView] {
        var views: [RegionalSkillMixQuotaView] = []
        for item in items {
            views.append(toRegionalSkillMixQuotaView(item))
        }
        return views
    }

    static func sumRegionalSkillMixQuotaView(_ view: RegionalSkillMixQuotaView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedCopay + Double(parsedUpdatedAt) + parsedDiscount
    }
}
