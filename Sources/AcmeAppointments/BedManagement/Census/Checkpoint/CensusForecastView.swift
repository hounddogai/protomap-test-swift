import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census forecast.
    final class CensusForecastView {
        var code: String
        var name: String
        var rate: String
        var archivedText: String
        var capacity: String
        var acuityText: String
        var ceiling: String
        var budget: String
        var statusLabel: String

        init(code: String, name: String, rate: String, archivedText: String, capacity: String, acuityText: String, ceiling: String, budget: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.rate = rate
            self.archivedText = archivedText
            self.capacity = capacity
            self.acuityText = acuityText
            self.ceiling = ceiling
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toCensusForecastView(_ item: CensusForecast) -> CensusForecastView {
        return CensusForecastView(
            code: item.code,
            name: item.name,
            rate: String(format: "%.2f", item.rate),
            archivedText: "\(item.archived)",
            capacity: String(item.capacity),
            acuityText: String(item.acuity),
            ceiling: String(format: "%.2f", item.ceiling),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusForecastViews(_ items: [CensusForecast]) -> [CensusForecastView] {
        var views: [CensusForecastView] = []
        for item in items {
            views.append(toCensusForecastView(item))
        }
        return views
    }

    static func sumCensusForecastView(_ view: CensusForecastView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedRate + Double(parsedCapacity) + Double(parsedAcuity)
    }
}
