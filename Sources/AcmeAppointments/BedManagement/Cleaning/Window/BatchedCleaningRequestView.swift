import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched cleaning request.
    final class BatchedCleaningRequestView {
        var codeText: String
        var name: String
        var summary: String
        var thresholdText: String
        var maximum: String
        var discount: String
        var quantityText: String
        var phone: String
        var region: String
        var diagnosisCodeText: String
        var sequence: String
        var statusLabel: String

        init(codeText: String, name: String, summary: String, thresholdText: String, maximum: String, discount: String, quantityText: String, phone: String, region: String, diagnosisCodeText: String, sequence: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.summary = summary
            self.thresholdText = thresholdText
            self.maximum = maximum
            self.discount = discount
            self.quantityText = quantityText
            self.phone = phone
            self.region = region
            self.diagnosisCodeText = diagnosisCodeText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCleaningRequestView(_ item: BatchedCleaningRequest) -> BatchedCleaningRequestView {
        return BatchedCleaningRequestView(
            codeText: item.code,
            name: item.name,
            summary: Kit.Text.truncate(item.summary, limit: 120),
            thresholdText: String(format: "%.2f", item.threshold),
            maximum: String(format: "%.2f", item.maximum),
            discount: String(format: "%.2f", item.discount),
            quantityText: String(item.quantity),
            phone: item.phone,
            region: item.region,
            diagnosisCodeText: item.diagnosisCode,
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCleaningRequestViews(_ items: [BatchedCleaningRequest]) -> [BatchedCleaningRequestView] {
        var views: [BatchedCleaningRequestView] = []
        for item in items {
            views.append(toBatchedCleaningRequestView(item))
        }
        return views
    }

    static func sumBatchedCleaningRequestView(_ view: BatchedCleaningRequestView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedThreshold + parsedMaximum + parsedDiscount
    }
}
