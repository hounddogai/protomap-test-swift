import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a manual shift score.
    final class ManualShiftScoreView {
        var code: String
        var name: String
        var startsAtText: String
        var channel: String
        var limit: String
        var statusLabel: String

        init(code: String, name: String, startsAtText: String, channel: String, limit: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.startsAtText = startsAtText
            self.channel = channel
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toManualShiftScoreView(_ item: ManualShiftScore) -> ManualShiftScoreView {
        return ManualShiftScoreView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            startsAtText: String(item.startsAt),
            channel: Kit.Text.truncate(item.channel, limit: 120),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualShiftScoreViews(_ items: [ManualShiftScore]) -> [ManualShiftScoreView] {
        var views: [ManualShiftScoreView] = []
        for item in items {
            views.append(toManualShiftScoreView(item))
        }
        return views
    }

    static func sumManualShiftScoreView(_ view: ManualShiftScoreView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedLimit)
    }
}
