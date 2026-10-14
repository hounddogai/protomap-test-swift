import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a primary accession claim.
    final class PrimaryAccessionClaimView {
        var codeText: String
        var name: String
        var attempts: String
        var categoryText: String
        var phoneText: String
        var localeText: String
        var approvedText: String
        var version: String
        var specialtyText: String
        var statusLabel: String

        init(codeText: String, name: String, attempts: String, categoryText: String, phoneText: String, localeText: String, approvedText: String, version: String, specialtyText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.attempts = attempts
            self.categoryText = categoryText
            self.phoneText = phoneText
            self.localeText = localeText
            self.approvedText = approvedText
            self.version = version
            self.specialtyText = specialtyText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryAccessionClaimView(_ item: PrimaryAccessionClaim) -> PrimaryAccessionClaimView {
        return PrimaryAccessionClaimView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            attempts: String(item.attempts),
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            phoneText: item.phone,
            localeText: item.locale,
            approvedText: "\(item.approved)",
            version: String(item.version),
            specialtyText: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryAccessionClaimViews(_ items: [PrimaryAccessionClaim]) -> [PrimaryAccessionClaimView] {
        var views: [PrimaryAccessionClaimView] = []
        for item in items {
            views.append(toPrimaryAccessionClaimView(item))
        }
        return views
    }

    static func sumPrimaryAccessionClaimView(_ view: PrimaryAccessionClaimView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedAttempts) + Double(parsedVersion)
    }
}
