import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer forecast.
    final class TransferForecastView {
        var code: String
        var name: String
        var weight: String
        var label: String
        var costText: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, name: String, weight: String, label: String, costText: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.weight = weight
            self.label = label
            self.costText = costText
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toTransferForecastView(_ item: TransferForecast) -> TransferForecastView {
        return TransferForecastView(
            code: item.code,
            name: item.name,
            weight: String(format: "%.2f", item.weight),
            label: item.label,
            costText: String(format: "%.2f", item.cost),
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferForecastViews(_ items: [TransferForecast]) -> [TransferForecastView] {
        var views: [TransferForecastView] = []
        for item in items {
            views.append(toTransferForecastView(item))
        }
        return views
    }

    static func sumTransferForecastView(_ view: TransferForecastView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedWeight + parsedCost
    }
}
