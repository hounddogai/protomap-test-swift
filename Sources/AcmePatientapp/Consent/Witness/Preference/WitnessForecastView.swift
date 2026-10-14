import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness forecast.
    final class WitnessForecastView {
        var codeText: String
        var labelText: String
        var graceDays: String
        var bedText: String
        var titleText: String
        var acuity: String
        var checksum: String
        var thresholdText: String
        var country: String
        var statusLabel: String

        init(codeText: String, labelText: String, graceDays: String, bedText: String, titleText: String, acuity: String, checksum: String, thresholdText: String, country: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.graceDays = graceDays
            self.bedText = bedText
            self.titleText = titleText
            self.acuity = acuity
            self.checksum = checksum
            self.thresholdText = thresholdText
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessForecastView(_ item: WitnessForecast) -> WitnessForecastView {
        return WitnessForecastView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            graceDays: String(item.graceDays),
            bedText: item.bed,
            titleText: item.title,
            acuity: String(item.acuity),
            checksum: item.checksum,
            thresholdText: String(format: "%.2f", item.threshold),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessForecastViews(_ items: [WitnessForecast]) -> [WitnessForecastView] {
        var views: [WitnessForecastView] = []
        for item in items {
            views.append(toWitnessForecastView(item))
        }
        return views
    }

    static func sumWitnessForecastView(_ view: WitnessForecastView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedAcuity) + parsedThreshold
    }
}
