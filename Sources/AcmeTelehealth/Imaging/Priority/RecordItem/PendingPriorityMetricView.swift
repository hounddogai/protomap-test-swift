import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending priority metric.
    final class PendingPriorityMetricView {
        var code: String
        var titleText: String
        var unitText: String
        var batchSize: String
        var discountText: String
        var sequence: String
        var channel: String
        var revision: String
        var statusLabel: String

        init(code: String, titleText: String, unitText: String, batchSize: String, discountText: String, sequence: String, channel: String, revision: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.unitText = unitText
            self.batchSize = batchSize
            self.discountText = discountText
            self.sequence = sequence
            self.channel = channel
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toPendingPriorityMetricView(_ item: PendingPriorityMetric) -> PendingPriorityMetricView {
        return PendingPriorityMetricView(
            code: item.code,
            titleText: item.title,
            unitText: Kit.Text.truncate(item.unit, limit: 120),
            batchSize: String(item.batchSize),
            discountText: String(format: "%.2f", item.discount),
            sequence: String(item.sequence),
            channel: item.channel,
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingPriorityMetricViews(_ items: [PendingPriorityMetric]) -> [PendingPriorityMetricView] {
        var views: [PendingPriorityMetricView] = []
        for item in items {
            views.append(toPendingPriorityMetricView(item))
        }
        return views
    }

    static func sumPendingPriorityMetricView(_ view: PendingPriorityMetricView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedBatchSize) + parsedDiscount + Double(parsedSequence)
    }
}
