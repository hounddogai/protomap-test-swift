import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a capped statement forecast.
    final class CappedStatementForecastView {
        var codeText: String
        var name: String
        var segment: String
        var maximum: String
        var ceilingText: String
        var procedureCode: String
        var ownerID: String
        var batchSize: String
        var minimum: String
        var patientRef: String
        var statusLabel: String

        init(codeText: String, name: String, segment: String, maximum: String, ceilingText: String, procedureCode: String, ownerID: String, batchSize: String, minimum: String, patientRef: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.segment = segment
            self.maximum = maximum
            self.ceilingText = ceilingText
            self.procedureCode = procedureCode
            self.ownerID = ownerID
            self.batchSize = batchSize
            self.minimum = minimum
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toCappedStatementForecastView(_ item: CappedStatementForecast) -> CappedStatementForecastView {
        return CappedStatementForecastView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            segment: Kit.Text.truncate(item.segment, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            ceilingText: String(format: "%.2f", item.ceiling),
            procedureCode: item.procedureCode,
            ownerID: item.ownerID,
            batchSize: String(item.batchSize),
            minimum: String(format: "%.2f", item.minimum),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedStatementForecastViews(_ items: [CappedStatementForecast]) -> [CappedStatementForecastView] {
        var views: [CappedStatementForecastView] = []
        for item in items {
            views.append(toCappedStatementForecastView(item))
        }
        return views
    }

    static func sumCappedStatementForecastView(_ view: CappedStatementForecastView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedMaximum + parsedCeiling + Double(parsedBatchSize)
    }
}
