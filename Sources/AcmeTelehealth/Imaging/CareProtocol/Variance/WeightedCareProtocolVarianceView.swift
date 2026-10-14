import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a weighted care protocol variance.
    final class WeightedCareProtocolVarianceView {
        var codeText: String
        var titleText: String
        var maximum: String
        var payerText: String
        var weightText: String
        var ratio: String
        var statusLabel: String

        init(codeText: String, titleText: String, maximum: String, payerText: String, weightText: String, ratio: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.maximum = maximum
            self.payerText = payerText
            self.weightText = weightText
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedCareProtocolVarianceView(_ item: WeightedCareProtocolVariance) -> WeightedCareProtocolVarianceView {
        return WeightedCareProtocolVarianceView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            payerText: item.payer,
            weightText: String(format: "%.2f", item.weight),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedCareProtocolVarianceViews(_ items: [WeightedCareProtocolVariance]) -> [WeightedCareProtocolVarianceView] {
        var views: [WeightedCareProtocolVarianceView] = []
        for item in items {
            views.append(toWeightedCareProtocolVarianceView(item))
        }
        return views
    }

    static func sumWeightedCareProtocolVarianceView(_ view: WeightedCareProtocolVarianceView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedMaximum + parsedWeight + parsedRatio
    }
}
