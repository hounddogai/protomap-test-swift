import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding batch.
    final class RoundingBatchView {
        var code: String
        var label: String
        var capacity: String
        var rate: String
        var description: String
        var statusLabel: String

        init(code: String, label: String, capacity: String, rate: String, description: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.rate = rate
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingBatchView(_ item: RoundingBatch) -> RoundingBatchView {
        return RoundingBatchView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            capacity: String(item.capacity),
            rate: String(format: "%.2f", item.rate),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingBatchViews(_ items: [RoundingBatch]) -> [RoundingBatchView] {
        var views: [RoundingBatchView] = []
        for item in items {
            views.append(toRoundingBatchView(item))
        }
        return views
    }

    static func sumRoundingBatchView(_ view: RoundingBatchView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedCapacity) + parsedRate
    }
}
