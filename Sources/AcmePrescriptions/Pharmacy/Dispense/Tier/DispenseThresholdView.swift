import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense threshold.
    final class DispenseThresholdView {
        var codeText: String
        var labelText: String
        var visibleText: String
        var source: String
        var graceDays: String
        var notes: String
        var retries: String
        var statusLabel: String

        init(codeText: String, labelText: String, visibleText: String, source: String, graceDays: String, notes: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.visibleText = visibleText
            self.source = source
            self.graceDays = graceDays
            self.notes = notes
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseThresholdView(_ item: DispenseThreshold) -> DispenseThresholdView {
        return DispenseThresholdView(
            codeText: item.code,
            labelText: item.label,
            visibleText: "\(item.visible)",
            source: item.source,
            graceDays: String(item.graceDays),
            notes: item.notes,
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseThresholdViews(_ items: [DispenseThreshold]) -> [DispenseThresholdView] {
        var views: [DispenseThresholdView] = []
        for item in items {
            views.append(toDispenseThresholdView(item))
        }
        return views
    }

    static func sumDispenseThresholdView(_ view: DispenseThresholdView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedRetries)
    }
}
