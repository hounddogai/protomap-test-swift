import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional revocation agreement.
    final class RegionalRevocationAgreementView {
        var codeText: String
        var label: String
        var specialty: String
        var categoryText: String
        var reviewer: String
        var maximum: String
        var contactEmail: String
        var ownerID: String
        var allergy: String
        var statusLabel: String

        init(codeText: String, label: String, specialty: String, categoryText: String, reviewer: String, maximum: String, contactEmail: String, ownerID: String, allergy: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.specialty = specialty
            self.categoryText = categoryText
            self.reviewer = reviewer
            self.maximum = maximum
            self.contactEmail = contactEmail
            self.ownerID = ownerID
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalRevocationAgreementView(_ item: RegionalRevocationAgreement) -> RegionalRevocationAgreementView {
        return RegionalRevocationAgreementView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            specialty: item.specialty,
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            maximum: String(format: "%.2f", item.maximum),
            contactEmail: item.contactEmail,
            ownerID: item.ownerID,
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalRevocationAgreementViews(_ items: [RegionalRevocationAgreement]) -> [RegionalRevocationAgreementView] {
        var views: [RegionalRevocationAgreementView] = []
        for item in items {
            views.append(toRegionalRevocationAgreementView(item))
        }
        return views
    }

    static func sumRegionalRevocationAgreementView(_ view: RegionalRevocationAgreementView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
