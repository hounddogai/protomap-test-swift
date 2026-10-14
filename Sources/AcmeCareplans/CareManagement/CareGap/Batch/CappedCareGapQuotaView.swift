import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a capped care gap quota.
    final class CappedCareGapQuotaView {
        var code: String
        var label: String
        var discount: String
        var unitText: String
        var scoreText: String
        var localeText: String
        var ratio: String
        var country: String
        var floorValueText: String
        var payer: String
        var statusLabel: String

        init(code: String, label: String, discount: String, unitText: String, scoreText: String, localeText: String, ratio: String, country: String, floorValueText: String, payer: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discount = discount
            self.unitText = unitText
            self.scoreText = scoreText
            self.localeText = localeText
            self.ratio = ratio
            self.country = country
            self.floorValueText = floorValueText
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toCappedCareGapQuotaView(_ item: CappedCareGapQuota) -> CappedCareGapQuotaView {
        return CappedCareGapQuotaView(
            code: item.code,
            label: item.label,
            discount: String(format: "%.2f", item.discount),
            unitText: Kit.Text.truncate(item.unit, limit: 120),
            scoreText: String(format: "%.2f", item.score),
            localeText: item.locale,
            ratio: String(format: "%.2f", item.ratio),
            country: item.country,
            floorValueText: String(format: "%.2f", item.floorValue),
            payer: Kit.Text.truncate(item.payer, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedCareGapQuotaViews(_ items: [CappedCareGapQuota]) -> [CappedCareGapQuotaView] {
        var views: [CappedCareGapQuotaView] = []
        for item in items {
            views.append(toCappedCareGapQuotaView(item))
        }
        return views
    }

    static func sumCappedCareGapQuotaView(_ view: CappedCareGapQuotaView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedDiscount + parsedScore + parsedRatio
    }
}
