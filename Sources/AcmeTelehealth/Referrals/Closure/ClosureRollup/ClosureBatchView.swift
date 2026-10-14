import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure batch.
    final class ClosureBatchView {
        var codeText: String
        var label: String
        var patientRefText: String
        var threshold: String
        var graceDays: String
        var maximum: String
        var facilityText: String
        var ceilingText: String
        var statusLabel: String

        init(codeText: String, label: String, patientRefText: String, threshold: String, graceDays: String, maximum: String, facilityText: String, ceilingText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.patientRefText = patientRefText
            self.threshold = threshold
            self.graceDays = graceDays
            self.maximum = maximum
            self.facilityText = facilityText
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toClosureBatchView(_ item: ClosureBatch) -> ClosureBatchView {
        return ClosureBatchView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 64),
            patientRefText: item.patientRef,
            threshold: String(format: "%.2f", item.threshold),
            graceDays: String(item.graceDays),
            maximum: String(format: "%.2f", item.maximum),
            facilityText: Kit.Text.truncate(item.facility, limit: 80),
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureBatchViews(_ items: [ClosureBatch]) -> [ClosureBatchView] {
        var views: [ClosureBatchView] = []
        for item in items {
            views.append(toClosureBatchView(item))
        }
        return views
    }

    static func sumClosureBatchView(_ view: ClosureBatchView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedThreshold + Double(parsedGraceDays) + parsedMaximum
    }
}
