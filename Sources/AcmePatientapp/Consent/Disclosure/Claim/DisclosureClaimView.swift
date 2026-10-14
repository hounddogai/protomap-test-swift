import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure claim.
    final class DisclosureClaimView {
        var code: String
        var name: String
        var country: String
        var score: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, name: String, country: String, score: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.country = country
            self.score = score
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureClaimView(_ item: DisclosureClaim) -> DisclosureClaimView {
        return DisclosureClaimView(
            code: item.code,
            name: item.name,
            country: item.country,
            score: String(format: "%.2f", item.score),
            clinicianIDText: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureClaimViews(_ items: [DisclosureClaim]) -> [DisclosureClaimView] {
        var views: [DisclosureClaimView] = []
        for item in items {
            views.append(toDisclosureClaimView(item))
        }
        return views
    }

    static func sumDisclosureClaimView(_ view: DisclosureClaimView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
