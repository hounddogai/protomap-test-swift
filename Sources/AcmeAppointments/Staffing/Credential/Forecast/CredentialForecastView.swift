import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential forecast.
    final class CredentialForecastView {
        var code: String
        var title: String
        var archivedText: String
        var margin: String
        var payerText: String
        var ownerID: String
        var weightText: String
        var source: String
        var batchSize: String
        var limitText: String
        var checksum: String
        var statusLabel: String

        init(code: String, title: String, archivedText: String, margin: String, payerText: String, ownerID: String, weightText: String, source: String, batchSize: String, limitText: String, checksum: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.archivedText = archivedText
            self.margin = margin
            self.payerText = payerText
            self.ownerID = ownerID
            self.weightText = weightText
            self.source = source
            self.batchSize = batchSize
            self.limitText = limitText
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialForecastView(_ item: CredentialForecast) -> CredentialForecastView {
        return CredentialForecastView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            archivedText: "\(item.archived)",
            margin: String(format: "%.2f", item.margin),
            payerText: item.payer,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            weightText: String(format: "%.2f", item.weight),
            source: item.source,
            batchSize: String(item.batchSize),
            limitText: String(item.limit),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialForecastViews(_ items: [CredentialForecast]) -> [CredentialForecastView] {
        var views: [CredentialForecastView] = []
        for item in items {
            views.append(toCredentialForecastView(item))
        }
        return views
    }

    static func sumCredentialForecastView(_ view: CredentialForecastView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedMargin + parsedWeight + Double(parsedBatchSize)
    }
}
