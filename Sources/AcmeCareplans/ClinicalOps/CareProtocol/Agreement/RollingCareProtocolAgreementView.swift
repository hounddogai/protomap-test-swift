import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rolling care protocol agreement.
    final class RollingCareProtocolAgreementView {
        var code: String
        var labelText: String
        var allergy: String
        var checksum: String
        var minimum: String
        var budget: String
        var region: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, labelText: String, allergy: String, checksum: String, minimum: String, budget: String, region: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.allergy = allergy
            self.checksum = checksum
            self.minimum = minimum
            self.budget = budget
            self.region = region
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCareProtocolAgreementView(_ item: RollingCareProtocolAgreement) -> RollingCareProtocolAgreementView {
        return RollingCareProtocolAgreementView(
            code: item.code,
            labelText: item.label,
            allergy: item.allergy,
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            minimum: String(format: "%.2f", item.minimum),
            budget: String(format: "%.2f", item.budget),
            region: Kit.Text.truncate(item.region, limit: 120),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCareProtocolAgreementViews(_ items: [RollingCareProtocolAgreement]) -> [RollingCareProtocolAgreementView] {
        var views: [RollingCareProtocolAgreementView] = []
        for item in items {
            views.append(toRollingCareProtocolAgreementView(item))
        }
        return views
    }

    static func sumRollingCareProtocolAgreementView(_ view: RollingCareProtocolAgreementView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedMinimum + parsedBudget
    }
}
