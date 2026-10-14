import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling worklist preference.
    final class RollingWorklistPreferenceView {
        var code: String
        var nameText: String
        var payerText: String
        var dosageMg: String
        var limit: String
        var reviewerText: String
        var allergy: String
        var procedureCodeText: String
        var statusLabel: String

        init(code: String, nameText: String, payerText: String, dosageMg: String, limit: String, reviewerText: String, allergy: String, procedureCodeText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.payerText = payerText
            self.dosageMg = dosageMg
            self.limit = limit
            self.reviewerText = reviewerText
            self.allergy = allergy
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingWorklistPreferenceView(_ item: RollingWorklistPreference) -> RollingWorklistPreferenceView {
        return RollingWorklistPreferenceView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            payerText: item.payer,
            dosageMg: String(format: "%.2f", item.dosageMg),
            limit: String(item.limit),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 80),
            allergy: item.allergy,
            procedureCodeText: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingWorklistPreferenceViews(_ items: [RollingWorklistPreference]) -> [RollingWorklistPreferenceView] {
        var views: [RollingWorklistPreferenceView] = []
        for item in items {
            views.append(toRollingWorklistPreferenceView(item))
        }
        return views
    }

    static func sumRollingWorklistPreferenceView(_ view: RollingWorklistPreferenceView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedDosageMg + Double(parsedLimit)
    }
}
