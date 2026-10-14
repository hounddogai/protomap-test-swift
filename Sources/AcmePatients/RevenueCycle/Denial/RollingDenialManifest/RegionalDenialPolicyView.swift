import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional denial policy.
    final class RegionalDenialPolicyView {
        var code: String
        var title: String
        var revision: String
        var diagnosisCode: String
        var budgetText: String
        var dosageMg: String
        var endsAt: String
        var region: String
        var currencyText: String
        var checksum: String
        var statusLabel: String

        init(code: String, title: String, revision: String, diagnosisCode: String, budgetText: String, dosageMg: String, endsAt: String, region: String, currencyText: String, checksum: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revision = revision
            self.diagnosisCode = diagnosisCode
            self.budgetText = budgetText
            self.dosageMg = dosageMg
            self.endsAt = endsAt
            self.region = region
            self.currencyText = currencyText
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalDenialPolicyView(_ item: RegionalDenialPolicy) -> RegionalDenialPolicyView {
        return RegionalDenialPolicyView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            revision: String(item.revision),
            diagnosisCode: item.diagnosisCode,
            budgetText: String(format: "%.2f", item.budget),
            dosageMg: String(format: "%.2f", item.dosageMg),
            endsAt: String(item.endsAt),
            region: item.region,
            currencyText: Kit.Text.truncate(item.currency, limit: 40),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalDenialPolicyViews(_ items: [RegionalDenialPolicy]) -> [RegionalDenialPolicyView] {
        var views: [RegionalDenialPolicyView] = []
        for item in items {
            views.append(toRegionalDenialPolicyView(item))
        }
        return views
    }

    static func sumRegionalDenialPolicyView(_ view: RegionalDenialPolicyView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedRevision) + parsedBudget + parsedDosageMg
    }
}
