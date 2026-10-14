import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance forecast.
    final class RemittanceForecastView {
        var codeText: String
        var name: String
        var diagnosisCodeText: String
        var attempts: String
        var batchSize: String
        var threshold: String
        var unit: String
        var currency: String
        var graceDays: String
        var label: String
        var statusLabel: String

        init(codeText: String, name: String, diagnosisCodeText: String, attempts: String, batchSize: String, threshold: String, unit: String, currency: String, graceDays: String, label: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.diagnosisCodeText = diagnosisCodeText
            self.attempts = attempts
            self.batchSize = batchSize
            self.threshold = threshold
            self.unit = unit
            self.currency = currency
            self.graceDays = graceDays
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceForecastView(_ item: RemittanceForecast) -> RemittanceForecastView {
        return RemittanceForecastView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            diagnosisCodeText: item.diagnosisCode,
            attempts: String(item.attempts),
            batchSize: String(item.batchSize),
            threshold: String(format: "%.2f", item.threshold),
            unit: item.unit,
            currency: item.currency,
            graceDays: String(item.graceDays),
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceForecastViews(_ items: [RemittanceForecast]) -> [RemittanceForecastView] {
        var views: [RemittanceForecastView] = []
        for item in items {
            views.append(toRemittanceForecastView(item))
        }
        return views
    }

    static func sumRemittanceForecastView(_ view: RemittanceForecastView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedAttempts) + Double(parsedBatchSize) + parsedThreshold
    }
}
