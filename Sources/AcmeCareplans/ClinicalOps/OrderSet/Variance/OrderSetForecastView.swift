import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set forecast.
    final class OrderSetForecastView {
        var codeText: String
        var labelText: String
        var checksum: String
        var pinned: String
        var graceDays: String
        var allergy: String
        var phone: String
        var statusLabel: String

        init(codeText: String, labelText: String, checksum: String, pinned: String, graceDays: String, allergy: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.checksum = checksum
            self.pinned = pinned
            self.graceDays = graceDays
            self.allergy = allergy
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetForecastView(_ item: OrderSetForecast) -> OrderSetForecastView {
        return OrderSetForecastView(
            codeText: item.code,
            labelText: item.label,
            checksum: item.checksum,
            pinned: "\(item.pinned)",
            graceDays: String(item.graceDays),
            allergy: item.allergy,
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetForecastViews(_ items: [OrderSetForecast]) -> [OrderSetForecastView] {
        var views: [OrderSetForecastView] = []
        for item in items {
            views.append(toOrderSetForecastView(item))
        }
        return views
    }

    static func sumOrderSetForecastView(_ view: OrderSetForecastView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
