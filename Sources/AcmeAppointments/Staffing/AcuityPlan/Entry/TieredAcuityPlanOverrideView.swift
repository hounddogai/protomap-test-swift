import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a tiered acuity plan override.
    final class TieredAcuityPlanOverrideView {
        var code: String
        var nameText: String
        var rate: String
        var minimum: String
        var weight: String
        var source: String
        var externalRef: String
        var maximum: String
        var budgetText: String
        var localeText: String
        var statusLabel: String

        init(code: String, nameText: String, rate: String, minimum: String, weight: String, source: String, externalRef: String, maximum: String, budgetText: String, localeText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.rate = rate
            self.minimum = minimum
            self.weight = weight
            self.source = source
            self.externalRef = externalRef
            self.maximum = maximum
            self.budgetText = budgetText
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredAcuityPlanOverrideView(_ item: TieredAcuityPlanOverride) -> TieredAcuityPlanOverrideView {
        return TieredAcuityPlanOverrideView(
            code: item.code,
            nameText: item.name,
            rate: String(format: "%.2f", item.rate),
            minimum: String(format: "%.2f", item.minimum),
            weight: String(format: "%.2f", item.weight),
            source: Kit.Text.truncate(item.source, limit: 80),
            externalRef: item.externalRef,
            maximum: String(format: "%.2f", item.maximum),
            budgetText: String(format: "%.2f", item.budget),
            localeText: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredAcuityPlanOverrideViews(_ items: [TieredAcuityPlanOverride]) -> [TieredAcuityPlanOverrideView] {
        var views: [TieredAcuityPlanOverrideView] = []
        for item in items {
            views.append(toTieredAcuityPlanOverrideView(item))
        }
        return views
    }

    static func sumTieredAcuityPlanOverrideView(_ view: TieredAcuityPlanOverrideView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedRate + parsedMinimum + parsedWeight
    }
}
