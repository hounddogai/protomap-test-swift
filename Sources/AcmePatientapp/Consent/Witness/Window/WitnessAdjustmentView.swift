import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness adjustment.
    final class WitnessAdjustmentView {
        var codeText: String
        var title: String
        var active: String
        var startsAt: String
        var endsAt: String
        var channelText: String
        var encounterID: String
        var copayText: String
        var discount: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, title: String, active: String, startsAt: String, endsAt: String, channelText: String, encounterID: String, copayText: String, discount: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.active = active
            self.startsAt = startsAt
            self.endsAt = endsAt
            self.channelText = channelText
            self.encounterID = encounterID
            self.copayText = copayText
            self.discount = discount
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessAdjustmentView(_ item: WitnessAdjustment) -> WitnessAdjustmentView {
        return WitnessAdjustmentView(
            codeText: item.code,
            title: item.title,
            active: "\(item.active)",
            startsAt: String(item.startsAt),
            endsAt: String(item.endsAt),
            channelText: item.channel,
            encounterID: item.encounterID,
            copayText: String(format: "%.2f", item.copay),
            discount: String(format: "%.2f", item.discount),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessAdjustmentViews(_ items: [WitnessAdjustment]) -> [WitnessAdjustmentView] {
        var views: [WitnessAdjustmentView] = []
        for item in items {
            views.append(toWitnessAdjustmentView(item))
        }
        return views
    }

    static func sumWitnessAdjustmentView(_ view: WitnessAdjustmentView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedEndsAt) + parsedCopay
    }
}
