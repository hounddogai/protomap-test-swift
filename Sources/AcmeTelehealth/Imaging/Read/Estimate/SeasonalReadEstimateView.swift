import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal read estimate.
    final class SeasonalReadEstimateView {
        var code: String
        var title: String
        var ownerID: String
        var updatedAtText: String
        var ceiling: String
        var payer: String
        var expiresAt: String
        var floorValue: String
        var retriesText: String
        var statusLabel: String

        init(code: String, title: String, ownerID: String, updatedAtText: String, ceiling: String, payer: String, expiresAt: String, floorValue: String, retriesText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.updatedAtText = updatedAtText
            self.ceiling = ceiling
            self.payer = payer
            self.expiresAt = expiresAt
            self.floorValue = floorValue
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalReadEstimateView(_ item: SeasonalReadEstimate) -> SeasonalReadEstimateView {
        return SeasonalReadEstimateView(
            code: item.code,
            title: item.title,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 64),
            updatedAtText: String(item.updatedAt),
            ceiling: String(format: "%.2f", item.ceiling),
            payer: item.payer,
            expiresAt: String(item.expiresAt),
            floorValue: String(format: "%.2f", item.floorValue),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalReadEstimateViews(_ items: [SeasonalReadEstimate]) -> [SeasonalReadEstimateView] {
        var views: [SeasonalReadEstimateView] = []
        for item in items {
            views.append(toSeasonalReadEstimateView(item))
        }
        return views
    }

    static func sumSeasonalReadEstimateView(_ view: SeasonalReadEstimateView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedUpdatedAt) + parsedCeiling + Double(parsedExpiresAt)
    }
}
