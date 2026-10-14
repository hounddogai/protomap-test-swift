import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form draft.
    final class ConsentFormDraftView {
        var code: String
        var name: String
        var costText: String
        var floorValueText: String
        var active: String
        var channelText: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, costText: String, floorValueText: String, active: String, channelText: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.costText = costText
            self.floorValueText = floorValueText
            self.active = active
            self.channelText = channelText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormDraftView(_ item: ConsentFormDraft) -> ConsentFormDraftView {
        return ConsentFormDraftView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            costText: String(format: "%.2f", item.cost),
            floorValueText: String(format: "%.2f", item.floorValue),
            active: "\(item.active)",
            channelText: item.channel,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormDraftViews(_ items: [ConsentFormDraft]) -> [ConsentFormDraftView] {
        var views: [ConsentFormDraftView] = []
        for item in items {
            views.append(toConsentFormDraftView(item))
        }
        return views
    }

    static func sumConsentFormDraftView(_ view: ConsentFormDraftView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedCost + parsedFloorValue + Double(parsedEndsAt)
    }
}
