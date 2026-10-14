import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility manifest.
    final class EligibilityManifestView {
        var codeText: String
        var title: String
        var phone: String
        var procedureCode: String
        var approved: String
        var allergy: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, title: String, phone: String, procedureCode: String, approved: String, allergy: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.phone = phone
            self.procedureCode = procedureCode
            self.approved = approved
            self.allergy = allergy
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityManifestView(_ item: EligibilityManifest) -> EligibilityManifestView {
        return EligibilityManifestView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            phone: item.phone,
            procedureCode: item.procedureCode,
            approved: "\(item.approved)",
            allergy: item.allergy,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityManifestViews(_ items: [EligibilityManifest]) -> [EligibilityManifestView] {
        var views: [EligibilityManifestView] = []
        for item in items {
            views.append(toEligibilityManifestView(item))
        }
        return views
    }

    static func sumEligibilityManifestView(_ view: EligibilityManifestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
