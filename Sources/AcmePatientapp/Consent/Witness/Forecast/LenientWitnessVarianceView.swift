import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient witness variance.
    final class LenientWitnessVarianceView {
        var code: String
        var name: String
        var label: String
        var minimum: String
        var rateText: String
        var allergy: String
        var batchSizeText: String
        var ratio: String
        var version: String
        var statusLabel: String

        init(code: String, name: String, label: String, minimum: String, rateText: String, allergy: String, batchSizeText: String, ratio: String, version: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.label = label
            self.minimum = minimum
            self.rateText = rateText
            self.allergy = allergy
            self.batchSizeText = batchSizeText
            self.ratio = ratio
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toLenientWitnessVarianceView(_ item: LenientWitnessVariance) -> LenientWitnessVarianceView {
        return LenientWitnessVarianceView(
            code: item.code,
            name: item.name,
            label: item.label,
            minimum: String(format: "%.2f", item.minimum),
            rateText: String(format: "%.2f", item.rate),
            allergy: Kit.Text.truncate(item.allergy, limit: 40),
            batchSizeText: String(item.batchSize),
            ratio: String(format: "%.2f", item.ratio),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientWitnessVarianceViews(_ items: [LenientWitnessVariance]) -> [LenientWitnessVarianceView] {
        var views: [LenientWitnessVarianceView] = []
        for item in items {
            views.append(toLenientWitnessVarianceView(item))
        }
        return views
    }

    static func sumLenientWitnessVarianceView(_ view: LenientWitnessVarianceView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedMinimum + parsedRate + Double(parsedBatchSize)
    }
}
