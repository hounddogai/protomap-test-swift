import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional denial claim.
    final class RegionalDenialClaimView {
        var codeText: String
        var title: String
        var ward: String
        var updatedAtText: String
        var facilityText: String
        var scoreText: String
        var category: String
        var minimum: String
        var statusLabel: String

        init(codeText: String, title: String, ward: String, updatedAtText: String, facilityText: String, scoreText: String, category: String, minimum: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ward = ward
            self.updatedAtText = updatedAtText
            self.facilityText = facilityText
            self.scoreText = scoreText
            self.category = category
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalDenialClaimView(_ item: RegionalDenialClaim) -> RegionalDenialClaimView {
        return RegionalDenialClaimView(
            codeText: item.code,
            title: item.title,
            ward: item.ward,
            updatedAtText: String(item.updatedAt),
            facilityText: item.facility,
            scoreText: String(format: "%.2f", item.score),
            category: item.category,
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalDenialClaimViews(_ items: [RegionalDenialClaim]) -> [RegionalDenialClaimView] {
        var views: [RegionalDenialClaimView] = []
        for item in items {
            views.append(toRegionalDenialClaimView(item))
        }
        return views
    }

    static func sumRegionalDenialClaimView(_ view: RegionalDenialClaimView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedUpdatedAt) + parsedScore + parsedMinimum
    }
}
