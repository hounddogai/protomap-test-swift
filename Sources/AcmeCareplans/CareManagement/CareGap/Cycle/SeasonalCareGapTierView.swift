import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a seasonal care gap tier.
    final class SeasonalCareGapTierView {
        var codeText: String
        var nameText: String
        var unit: String
        var facilityText: String
        var phone: String
        var ownerID: String
        var specialty: String
        var scoreText: String
        var statusLabel: String

        init(codeText: String, nameText: String, unit: String, facilityText: String, phone: String, ownerID: String, specialty: String, scoreText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.unit = unit
            self.facilityText = facilityText
            self.phone = phone
            self.ownerID = ownerID
            self.specialty = specialty
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCareGapTierView(_ item: SeasonalCareGapTier) -> SeasonalCareGapTierView {
        return SeasonalCareGapTierView(
            codeText: item.code,
            nameText: item.name,
            unit: item.unit,
            facilityText: Kit.Text.truncate(item.facility, limit: 64),
            phone: item.phone,
            ownerID: item.ownerID,
            specialty: item.specialty,
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCareGapTierViews(_ items: [SeasonalCareGapTier]) -> [SeasonalCareGapTierView] {
        var views: [SeasonalCareGapTierView] = []
        for item in items {
            views.append(toSeasonalCareGapTierView(item))
        }
        return views
    }

    static func sumSeasonalCareGapTierView(_ view: SeasonalCareGapTierView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
