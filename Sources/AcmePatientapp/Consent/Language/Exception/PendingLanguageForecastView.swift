import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a pending language forecast.
    final class PendingLanguageForecastView {
        var code: String
        var label: String
        var batchSize: String
        var graceDays: String
        var updatedAt: String
        var country: String
        var channelText: String
        var statusLabel: String

        init(code: String, label: String, batchSize: String, graceDays: String, updatedAt: String, country: String, channelText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.graceDays = graceDays
            self.updatedAt = updatedAt
            self.country = country
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingLanguageForecastView(_ item: PendingLanguageForecast) -> PendingLanguageForecastView {
        return PendingLanguageForecastView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 64),
            batchSize: String(item.batchSize),
            graceDays: String(item.graceDays),
            updatedAt: String(item.updatedAt),
            country: item.country,
            channelText: Kit.Text.truncate(item.channel, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingLanguageForecastViews(_ items: [PendingLanguageForecast]) -> [PendingLanguageForecastView] {
        var views: [PendingLanguageForecastView] = []
        for item in items {
            views.append(toPendingLanguageForecastView(item))
        }
        return views
    }

    static func sumPendingLanguageForecastView(_ view: PendingLanguageForecastView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedGraceDays) + Double(parsedUpdatedAt)
    }
}
