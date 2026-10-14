import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set threshold.
    final class OrderSetThresholdView {
        var code: String
        var title: String
        var sequenceText: String
        var priority: String
        var reviewer: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, title: String, sequenceText: String, priority: String, reviewer: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sequenceText = sequenceText
            self.priority = priority
            self.reviewer = reviewer
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetThresholdView(_ item: OrderSetThreshold) -> OrderSetThresholdView {
        return OrderSetThresholdView(
            code: item.code,
            title: item.title,
            sequenceText: String(item.sequence),
            priority: String(item.priority),
            reviewer: item.reviewer,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetThresholdViews(_ items: [OrderSetThreshold]) -> [OrderSetThresholdView] {
        var views: [OrderSetThresholdView] = []
        for item in items {
            views.append(toOrderSetThresholdView(item))
        }
        return views
    }

    static func sumOrderSetThresholdView(_ view: OrderSetThresholdView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedSequence) + Double(parsedPriority) + parsedDosageMg
    }
}
