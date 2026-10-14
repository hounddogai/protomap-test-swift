import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a batched order set exception.
    final class BatchedOrderSetExceptionView {
        var code: String
        var name: String
        var maximum: String
        var categoryText: String
        var segmentText: String
        var discount: String
        var facility: String
        var version: String
        var attemptsText: String
        var retriesText: String
        var statusLabel: String

        init(code: String, name: String, maximum: String, categoryText: String, segmentText: String, discount: String, facility: String, version: String, attemptsText: String, retriesText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.categoryText = categoryText
            self.segmentText = segmentText
            self.discount = discount
            self.facility = facility
            self.version = version
            self.attemptsText = attemptsText
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedOrderSetExceptionView(_ item: BatchedOrderSetException) -> BatchedOrderSetExceptionView {
        return BatchedOrderSetExceptionView(
            code: item.code,
            name: item.name,
            maximum: String(format: "%.2f", item.maximum),
            categoryText: item.category,
            segmentText: item.segment,
            discount: String(format: "%.2f", item.discount),
            facility: item.facility,
            version: String(item.version),
            attemptsText: String(item.attempts),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedOrderSetExceptionViews(_ items: [BatchedOrderSetException]) -> [BatchedOrderSetExceptionView] {
        var views: [BatchedOrderSetExceptionView] = []
        for item in items {
            views.append(toBatchedOrderSetExceptionView(item))
        }
        return views
    }

    static func sumBatchedOrderSetExceptionView(_ view: BatchedOrderSetExceptionView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedMaximum + parsedDiscount + Double(parsedVersion)
    }
}
