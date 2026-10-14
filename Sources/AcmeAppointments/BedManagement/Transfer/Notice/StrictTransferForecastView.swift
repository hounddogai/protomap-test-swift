import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a strict transfer forecast.
    final class StrictTransferForecastView {
        var codeText: String
        var label: String
        var floorValue: String
        var pinned: String
        var currencyText: String
        var minimumText: String
        var capacity: String
        var payer: String
        var statusLabel: String

        init(codeText: String, label: String, floorValue: String, pinned: String, currencyText: String, minimumText: String, capacity: String, payer: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.floorValue = floorValue
            self.pinned = pinned
            self.currencyText = currencyText
            self.minimumText = minimumText
            self.capacity = capacity
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toStrictTransferForecastView(_ item: StrictTransferForecast) -> StrictTransferForecastView {
        return StrictTransferForecastView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            pinned: "\(item.pinned)",
            currencyText: item.currency,
            minimumText: String(format: "%.2f", item.minimum),
            capacity: String(item.capacity),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictTransferForecastViews(_ items: [StrictTransferForecast]) -> [StrictTransferForecastView] {
        var views: [StrictTransferForecastView] = []
        for item in items {
            views.append(toStrictTransferForecastView(item))
        }
        return views
    }

    static func sumStrictTransferForecastView(_ view: StrictTransferForecastView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedFloorValue + parsedMinimum + Double(parsedCapacity)
    }
}
