import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a lenient network score.
    final class LenientNetworkScoreView {
        var code: String
        var labelText: String
        var pinned: String
        var floorValueText: String
        var copay: String
        var summary: String
        var endsAtText: String
        var attempts: String
        var statusLabel: String

        init(code: String, labelText: String, pinned: String, floorValueText: String, copay: String, summary: String, endsAtText: String, attempts: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.pinned = pinned
            self.floorValueText = floorValueText
            self.copay = copay
            self.summary = summary
            self.endsAtText = endsAtText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toLenientNetworkScoreView(_ item: LenientNetworkScore) -> LenientNetworkScoreView {
        return LenientNetworkScoreView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: Kit.Text.truncate(item.label, limit: 40),
            pinned: "\(item.pinned)",
            floorValueText: String(format: "%.2f", item.floorValue),
            copay: String(format: "%.2f", item.copay),
            summary: item.summary,
            endsAtText: String(item.endsAt),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientNetworkScoreViews(_ items: [LenientNetworkScore]) -> [LenientNetworkScoreView] {
        var views: [LenientNetworkScoreView] = []
        for item in items {
            views.append(toLenientNetworkScoreView(item))
        }
        return views
    }

    static func sumLenientNetworkScoreView(_ view: LenientNetworkScoreView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedFloorValue + parsedCopay + Double(parsedEndsAt)
    }
}
