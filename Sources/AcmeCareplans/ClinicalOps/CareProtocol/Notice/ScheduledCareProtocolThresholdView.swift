import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a scheduled care protocol threshold.
    final class ScheduledCareProtocolThresholdView {
        var code: String
        var name: String
        var patientRef: String
        var attemptsText: String
        var channelText: String
        var statusLabel: String

        init(code: String, name: String, patientRef: String, attemptsText: String, channelText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.attemptsText = attemptsText
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCareProtocolThresholdView(_ item: ScheduledCareProtocolThreshold) -> ScheduledCareProtocolThresholdView {
        return ScheduledCareProtocolThresholdView(
            code: item.code,
            name: item.name,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 120),
            attemptsText: String(item.attempts),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCareProtocolThresholdViews(_ items: [ScheduledCareProtocolThreshold]) -> [ScheduledCareProtocolThresholdView] {
        var views: [ScheduledCareProtocolThresholdView] = []
        for item in items {
            views.append(toScheduledCareProtocolThresholdView(item))
        }
        return views
    }

    static func sumScheduledCareProtocolThresholdView(_ view: ScheduledCareProtocolThresholdView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAttempts)
    }
}
