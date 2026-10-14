import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority estimate.
    final class PriorityEstimateView {
        var code: String
        var labelText: String
        var weight: String
        var channel: String
        var dosageMg: String
        var externalRef: String
        var batchSize: String
        var limitText: String
        var copay: String
        var payer: String
        var statusLabel: String

        init(code: String, labelText: String, weight: String, channel: String, dosageMg: String, externalRef: String, batchSize: String, limitText: String, copay: String, payer: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.weight = weight
            self.channel = channel
            self.dosageMg = dosageMg
            self.externalRef = externalRef
            self.batchSize = batchSize
            self.limitText = limitText
            self.copay = copay
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityEstimateView(_ item: PriorityEstimate) -> PriorityEstimateView {
        return PriorityEstimateView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            weight: String(format: "%.2f", item.weight),
            channel: Kit.Text.truncate(item.channel, limit: 64),
            dosageMg: String(format: "%.2f", item.dosageMg),
            externalRef: item.externalRef,
            batchSize: String(item.batchSize),
            limitText: String(item.limit),
            copay: String(format: "%.2f", item.copay),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityEstimateViews(_ items: [PriorityEstimate]) -> [PriorityEstimateView] {
        var views: [PriorityEstimateView] = []
        for item in items {
            views.append(toPriorityEstimateView(item))
        }
        return views
    }

    static func sumPriorityEstimateView(_ view: PriorityEstimateView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedWeight + parsedDosageMg + Double(parsedBatchSize)
    }
}
