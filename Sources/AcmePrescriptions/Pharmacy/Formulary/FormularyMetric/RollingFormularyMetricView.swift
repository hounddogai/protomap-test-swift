import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling formulary metric.
    final class RollingFormularyMetricView {
        var codeText: String
        var title: String
        var graceDays: String
        var thresholdText: String
        var checksum: String
        var batchSize: String
        var statusLabel: String

        init(codeText: String, title: String, graceDays: String, thresholdText: String, checksum: String, batchSize: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.graceDays = graceDays
            self.thresholdText = thresholdText
            self.checksum = checksum
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toRollingFormularyMetricView(_ item: RollingFormularyMetric) -> RollingFormularyMetricView {
        return RollingFormularyMetricView(
            codeText: item.code,
            title: item.title,
            graceDays: String(item.graceDays),
            thresholdText: String(format: "%.2f", item.threshold),
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingFormularyMetricViews(_ items: [RollingFormularyMetric]) -> [RollingFormularyMetricView] {
        var views: [RollingFormularyMetricView] = []
        for item in items {
            views.append(toRollingFormularyMetricView(item))
        }
        return views
    }

    static func sumRollingFormularyMetricView(_ view: RollingFormularyMetricView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedGraceDays) + parsedThreshold + Double(parsedBatchSize)
    }
}
