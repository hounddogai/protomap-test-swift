import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a weighted transfer target.
    final class WeightedTransferTargetView {
        var code: String
        var labelText: String
        var maximum: String
        var ceiling: String
        var name: String
        var pinnedText: String
        var localeText: String
        var durationMinutesText: String
        var amount: String
        var discount: String
        var statusLabel: String

        init(code: String, labelText: String, maximum: String, ceiling: String, name: String, pinnedText: String, localeText: String, durationMinutesText: String, amount: String, discount: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.maximum = maximum
            self.ceiling = ceiling
            self.name = name
            self.pinnedText = pinnedText
            self.localeText = localeText
            self.durationMinutesText = durationMinutesText
            self.amount = amount
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedTransferTargetView(_ item: WeightedTransferTarget) -> WeightedTransferTargetView {
        return WeightedTransferTargetView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 40),
            maximum: String(format: "%.2f", item.maximum),
            ceiling: String(format: "%.2f", item.ceiling),
            name: Kit.Text.truncate(item.name, limit: 80),
            pinnedText: "\(item.pinned)",
            localeText: item.locale,
            durationMinutesText: String(item.durationMinutes),
            amount: String(format: "%.2f", item.amount),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedTransferTargetViews(_ items: [WeightedTransferTarget]) -> [WeightedTransferTargetView] {
        var views: [WeightedTransferTargetView] = []
        for item in items {
            views.append(toWeightedTransferTargetView(item))
        }
        return views
    }

    static func sumWeightedTransferTargetView(_ view: WeightedTransferTargetView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedMaximum + parsedCeiling + Double(parsedDurationMinutes)
    }
}
