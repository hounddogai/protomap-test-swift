import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier milestone.
    final class CourierMilestoneView {
        var code: String
        var labelText: String
        var windowDays: String
        var attempts: String
        var channel: String
        var patientRefText: String
        var statusLabel: String

        init(code: String, labelText: String, windowDays: String, attempts: String, channel: String, patientRefText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.windowDays = windowDays
            self.attempts = attempts
            self.channel = channel
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toCourierMilestoneView(_ item: CourierMilestone) -> CourierMilestoneView {
        return CourierMilestoneView(
            code: item.code,
            labelText: item.label,
            windowDays: String(item.windowDays),
            attempts: String(item.attempts),
            channel: item.channel,
            patientRefText: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierMilestoneViews(_ items: [CourierMilestone]) -> [CourierMilestoneView] {
        var views: [CourierMilestoneView] = []
        for item in items {
            views.append(toCourierMilestoneView(item))
        }
        return views
    }

    static func sumCourierMilestoneView(_ view: CourierMilestoneView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedAttempts)
    }
}
