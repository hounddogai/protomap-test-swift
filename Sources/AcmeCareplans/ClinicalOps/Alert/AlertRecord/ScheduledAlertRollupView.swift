import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a scheduled alert rollup.
    final class ScheduledAlertRollupView {
        var code: String
        var name: String
        var label: String
        var ward: String
        var attempts: String
        var title: String
        var channel: String
        var activeText: String
        var minimum: String
        var statusLabel: String

        init(code: String, name: String, label: String, ward: String, attempts: String, title: String, channel: String, activeText: String, minimum: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.label = label
            self.ward = ward
            self.attempts = attempts
            self.title = title
            self.channel = channel
            self.activeText = activeText
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledAlertRollupView(_ item: ScheduledAlertRollup) -> ScheduledAlertRollupView {
        return ScheduledAlertRollupView(
            code: item.code,
            name: item.name,
            label: Kit.Text.truncate(item.label, limit: 64),
            ward: item.ward,
            attempts: String(item.attempts),
            title: item.title,
            channel: item.channel,
            activeText: "\(item.active)",
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledAlertRollupViews(_ items: [ScheduledAlertRollup]) -> [ScheduledAlertRollupView] {
        var views: [ScheduledAlertRollupView] = []
        for item in items {
            views.append(toScheduledAlertRollupView(item))
        }
        return views
    }

    static func sumScheduledAlertRollupView(_ view: ScheduledAlertRollupView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedAttempts) + parsedMinimum
    }
}
