import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending assessment preference.
    final class PendingAssessmentPreferenceView {
        var code: String
        var label: String
        var threshold: String
        var durationMinutes: String
        var pinnedText: String
        var ratio: String
        var channelText: String
        var activeText: String
        var statusLabel: String

        init(code: String, label: String, threshold: String, durationMinutes: String, pinnedText: String, ratio: String, channelText: String, activeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.durationMinutes = durationMinutes
            self.pinnedText = pinnedText
            self.ratio = ratio
            self.channelText = channelText
            self.activeText = activeText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingAssessmentPreferenceView(_ item: PendingAssessmentPreference) -> PendingAssessmentPreferenceView {
        return PendingAssessmentPreferenceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 80),
            threshold: String(format: "%.2f", item.threshold),
            durationMinutes: String(item.durationMinutes),
            pinnedText: "\(item.pinned)",
            ratio: String(format: "%.2f", item.ratio),
            channelText: item.channel,
            activeText: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingAssessmentPreferenceViews(_ items: [PendingAssessmentPreference]) -> [PendingAssessmentPreferenceView] {
        var views: [PendingAssessmentPreferenceView] = []
        for item in items {
            views.append(toPendingAssessmentPreferenceView(item))
        }
        return views
    }

    static func sumPendingAssessmentPreferenceView(_ view: PendingAssessmentPreferenceView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedThreshold + Double(parsedDurationMinutes) + parsedRatio
    }
}
