import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a lenient order set target.
    final class LenientOrderSetTargetView {
        var code: String
        var nameText: String
        var budget: String
        var revision: String
        var phone: String
        var acuityText: String
        var attempts: String
        var allergy: String
        var version: String
        var country: String
        var statusLabel: String

        init(code: String, nameText: String, budget: String, revision: String, phone: String, acuityText: String, attempts: String, allergy: String, version: String, country: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.budget = budget
            self.revision = revision
            self.phone = phone
            self.acuityText = acuityText
            self.attempts = attempts
            self.allergy = allergy
            self.version = version
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toLenientOrderSetTargetView(_ item: LenientOrderSetTarget) -> LenientOrderSetTargetView {
        return LenientOrderSetTargetView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            budget: String(format: "%.2f", item.budget),
            revision: String(item.revision),
            phone: item.phone,
            acuityText: String(item.acuity),
            attempts: String(item.attempts),
            allergy: item.allergy,
            version: String(item.version),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientOrderSetTargetViews(_ items: [LenientOrderSetTarget]) -> [LenientOrderSetTargetView] {
        var views: [LenientOrderSetTargetView] = []
        for item in items {
            views.append(toLenientOrderSetTargetView(item))
        }
        return views
    }

    static func sumLenientOrderSetTargetView(_ view: LenientOrderSetTargetView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedBudget + Double(parsedRevision) + Double(parsedAcuity)
    }
}
