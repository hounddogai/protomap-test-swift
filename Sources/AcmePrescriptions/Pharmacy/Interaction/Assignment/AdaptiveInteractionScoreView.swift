import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive interaction score.
    final class AdaptiveInteractionScoreView {
        var code: String
        var label: String
        var copayText: String
        var durationMinutesText: String
        var floorValue: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, label: String, copayText: String, durationMinutesText: String, floorValue: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.copayText = copayText
            self.durationMinutesText = durationMinutesText
            self.floorValue = floorValue
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveInteractionScoreView(_ item: AdaptiveInteractionScore) -> AdaptiveInteractionScoreView {
        return AdaptiveInteractionScoreView(
            code: item.code,
            label: item.label,
            copayText: String(format: "%.2f", item.copay),
            durationMinutesText: String(item.durationMinutes),
            floorValue: String(format: "%.2f", item.floorValue),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveInteractionScoreViews(_ items: [AdaptiveInteractionScore]) -> [AdaptiveInteractionScoreView] {
        var views: [AdaptiveInteractionScoreView] = []
        for item in items {
            views.append(toAdaptiveInteractionScoreView(item))
        }
        return views
    }

    static func sumAdaptiveInteractionScoreView(_ view: AdaptiveInteractionScoreView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedCopay + Double(parsedDurationMinutes) + parsedFloorValue
    }
}
