import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a seasonal language request.
    final class SeasonalLanguageRequestView {
        var code: String
        var name: String
        var expiresAt: String
        var score: String
        var allergyText: String
        var capacityText: String
        var statusLabel: String

        init(code: String, name: String, expiresAt: String, score: String, allergyText: String, capacityText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.score = score
            self.allergyText = allergyText
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalLanguageRequestView(_ item: SeasonalLanguageRequest) -> SeasonalLanguageRequestView {
        return SeasonalLanguageRequestView(
            code: item.code,
            name: item.name,
            expiresAt: String(item.expiresAt),
            score: String(format: "%.2f", item.score),
            allergyText: item.allergy,
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalLanguageRequestViews(_ items: [SeasonalLanguageRequest]) -> [SeasonalLanguageRequestView] {
        var views: [SeasonalLanguageRequestView] = []
        for item in items {
            views.append(toSeasonalLanguageRequestView(item))
        }
        return views
    }

    static func sumSeasonalLanguageRequestView(_ view: SeasonalLanguageRequestView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedExpiresAt) + parsedScore + Double(parsedCapacity)
    }
}
