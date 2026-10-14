import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a strict handoff adjustment.
    final class StrictHandoffAdjustmentView {
        var code: String
        var name: String
        var ratio: String
        var unit: String
        var graceDaysText: String
        var clinicianID: String
        var maximum: String
        var externalRefText: String
        var category: String
        var regionText: String
        var statusLabel: String

        init(code: String, name: String, ratio: String, unit: String, graceDaysText: String, clinicianID: String, maximum: String, externalRefText: String, category: String, regionText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.unit = unit
            self.graceDaysText = graceDaysText
            self.clinicianID = clinicianID
            self.maximum = maximum
            self.externalRefText = externalRefText
            self.category = category
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictHandoffAdjustmentView(_ item: StrictHandoffAdjustment) -> StrictHandoffAdjustmentView {
        return StrictHandoffAdjustmentView(
            code: item.code,
            name: item.name,
            ratio: String(format: "%.2f", item.ratio),
            unit: item.unit,
            graceDaysText: String(item.graceDays),
            clinicianID: item.clinicianID,
            maximum: String(format: "%.2f", item.maximum),
            externalRefText: item.externalRef,
            category: item.category,
            regionText: Kit.Text.truncate(item.region, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictHandoffAdjustmentViews(_ items: [StrictHandoffAdjustment]) -> [StrictHandoffAdjustmentView] {
        var views: [StrictHandoffAdjustmentView] = []
        for item in items {
            views.append(toStrictHandoffAdjustmentView(item))
        }
        return views
    }

    static func sumStrictHandoffAdjustmentView(_ view: StrictHandoffAdjustmentView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedRatio + Double(parsedGraceDays) + parsedMaximum
    }
}
