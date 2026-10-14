import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall bundle.
    final class RecallBundleView {
        var code: String
        var label: String
        var attempts: String
        var unit: String
        var threshold: String
        var statusLabel: String

        init(code: String, label: String, attempts: String, unit: String, threshold: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.unit = unit
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toRecallBundleView(_ item: RecallBundle) -> RecallBundleView {
        return RecallBundleView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            attempts: String(item.attempts),
            unit: item.unit,
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallBundleViews(_ items: [RecallBundle]) -> [RecallBundleView] {
        var views: [RecallBundleView] = []
        for item in items {
            views.append(toRecallBundleView(item))
        }
        return views
    }

    static func sumRecallBundleView(_ view: RecallBundleView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedAttempts) + parsedThreshold
    }
}
