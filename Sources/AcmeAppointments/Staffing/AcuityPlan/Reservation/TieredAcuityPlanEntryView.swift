import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a tiered acuity plan entry.
    final class TieredAcuityPlanEntryView {
        var code: String
        var name: String
        var graceDays: String
        var acuity: String
        var minimumText: String
        var statusLabel: String

        init(code: String, name: String, graceDays: String, acuity: String, minimumText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.acuity = acuity
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredAcuityPlanEntryView(_ item: TieredAcuityPlanEntry) -> TieredAcuityPlanEntryView {
        return TieredAcuityPlanEntryView(
            code: item.code,
            name: item.name,
            graceDays: String(item.graceDays),
            acuity: String(item.acuity),
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredAcuityPlanEntryViews(_ items: [TieredAcuityPlanEntry]) -> [TieredAcuityPlanEntryView] {
        var views: [TieredAcuityPlanEntryView] = []
        for item in items {
            views.append(toTieredAcuityPlanEntryView(item))
        }
        return views
    }

    static func sumTieredAcuityPlanEntryView(_ view: TieredAcuityPlanEntryView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedAcuity) + parsedMinimum
    }
}
