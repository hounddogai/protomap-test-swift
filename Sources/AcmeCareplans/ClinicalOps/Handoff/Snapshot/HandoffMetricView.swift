import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff metric.
    final class HandoffMetricView {
        var code: String
        var label: String
        var notesText: String
        var rate: String
        var batchSize: String
        var pinned: String
        var acuity: String
        var wardText: String
        var statusLabel: String

        init(code: String, label: String, notesText: String, rate: String, batchSize: String, pinned: String, acuity: String, wardText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.notesText = notesText
            self.rate = rate
            self.batchSize = batchSize
            self.pinned = pinned
            self.acuity = acuity
            self.wardText = wardText
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffMetricView(_ item: HandoffMetric) -> HandoffMetricView {
        return HandoffMetricView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            notesText: item.notes,
            rate: String(format: "%.2f", item.rate),
            batchSize: String(item.batchSize),
            pinned: "\(item.pinned)",
            acuity: String(item.acuity),
            wardText: Kit.Text.truncate(item.ward, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffMetricViews(_ items: [HandoffMetric]) -> [HandoffMetricView] {
        var views: [HandoffMetricView] = []
        for item in items {
            views.append(toHandoffMetricView(item))
        }
        return views
    }

    static func sumHandoffMetricView(_ view: HandoffMetricView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedRate + Double(parsedBatchSize) + Double(parsedAcuity)
    }
}
