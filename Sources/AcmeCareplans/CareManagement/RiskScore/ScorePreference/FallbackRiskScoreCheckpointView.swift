import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback risk score checkpoint.
    final class FallbackRiskScoreCheckpointView {
        var codeText: String
        var title: String
        var windowDaysText: String
        var pinnedText: String
        var channelText: String
        var visible: String
        var statusLabel: String

        init(codeText: String, title: String, windowDaysText: String, pinnedText: String, channelText: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.windowDaysText = windowDaysText
            self.pinnedText = pinnedText
            self.channelText = channelText
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackRiskScoreCheckpointView(_ item: FallbackRiskScoreCheckpoint) -> FallbackRiskScoreCheckpointView {
        return FallbackRiskScoreCheckpointView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            windowDaysText: String(item.windowDays),
            pinnedText: "\(item.pinned)",
            channelText: item.channel,
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackRiskScoreCheckpointViews(_ items: [FallbackRiskScoreCheckpoint]) -> [FallbackRiskScoreCheckpointView] {
        var views: [FallbackRiskScoreCheckpointView] = []
        for item in items {
            views.append(toFallbackRiskScoreCheckpointView(item))
        }
        return views
    }

    static func sumFallbackRiskScoreCheckpointView(_ view: FallbackRiskScoreCheckpointView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedWindowDays)
    }
}
