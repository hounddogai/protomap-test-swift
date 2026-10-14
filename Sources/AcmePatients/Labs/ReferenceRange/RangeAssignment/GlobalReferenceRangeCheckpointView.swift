import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a global reference range checkpoint.
    final class GlobalReferenceRangeCheckpointView {
        var code: String
        var nameText: String
        var acuity: String
        var quantityText: String
        var localeText: String
        var ratio: String
        var payerText: String
        var batchSize: String
        var retriesText: String
        var weight: String
        var statusLabel: String

        init(code: String, nameText: String, acuity: String, quantityText: String, localeText: String, ratio: String, payerText: String, batchSize: String, retriesText: String, weight: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.acuity = acuity
            self.quantityText = quantityText
            self.localeText = localeText
            self.ratio = ratio
            self.payerText = payerText
            self.batchSize = batchSize
            self.retriesText = retriesText
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalReferenceRangeCheckpointView(_ item: GlobalReferenceRangeCheckpoint) -> GlobalReferenceRangeCheckpointView {
        return GlobalReferenceRangeCheckpointView(
            code: item.code,
            nameText: item.name,
            acuity: String(item.acuity),
            quantityText: String(item.quantity),
            localeText: item.locale,
            ratio: String(format: "%.2f", item.ratio),
            payerText: item.payer,
            batchSize: String(item.batchSize),
            retriesText: String(item.retries),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalReferenceRangeCheckpointViews(_ items: [GlobalReferenceRangeCheckpoint]) -> [GlobalReferenceRangeCheckpointView] {
        var views: [GlobalReferenceRangeCheckpointView] = []
        for item in items {
            views.append(toGlobalReferenceRangeCheckpointView(item))
        }
        return views
    }

    static func sumGlobalReferenceRangeCheckpointView(_ view: GlobalReferenceRangeCheckpointView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedAcuity) + Double(parsedQuantity) + parsedRatio
    }
}
