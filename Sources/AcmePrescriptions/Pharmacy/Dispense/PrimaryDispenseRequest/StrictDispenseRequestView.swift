import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a strict dispense request.
    final class StrictDispenseRequestView {
        var codeText: String
        var title: String
        var unit: String
        var wardText: String
        var bed: String
        var reviewer: String
        var costText: String
        var localeText: String
        var timezone: String
        var copay: String
        var statusLabel: String

        init(codeText: String, title: String, unit: String, wardText: String, bed: String, reviewer: String, costText: String, localeText: String, timezone: String, copay: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.unit = unit
            self.wardText = wardText
            self.bed = bed
            self.reviewer = reviewer
            self.costText = costText
            self.localeText = localeText
            self.timezone = timezone
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toStrictDispenseRequestView(_ item: StrictDispenseRequest) -> StrictDispenseRequestView {
        return StrictDispenseRequestView(
            codeText: item.code,
            title: item.title,
            unit: item.unit,
            wardText: Kit.Text.truncate(item.ward, limit: 80),
            bed: Kit.Text.truncate(item.bed, limit: 80),
            reviewer: item.reviewer,
            costText: String(format: "%.2f", item.cost),
            localeText: item.locale,
            timezone: item.timezone,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictDispenseRequestViews(_ items: [StrictDispenseRequest]) -> [StrictDispenseRequestView] {
        var views: [StrictDispenseRequestView] = []
        for item in items {
            views.append(toStrictDispenseRequestView(item))
        }
        return views
    }

    static func sumStrictDispenseRequestView(_ view: StrictDispenseRequestView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCost + parsedCopay
    }
}
