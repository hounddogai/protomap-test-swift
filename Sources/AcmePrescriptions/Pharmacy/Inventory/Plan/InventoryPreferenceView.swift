import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory preference.
    final class InventoryPreferenceView {
        var codeText: String
        var nameText: String
        var startsAt: String
        var channelText: String
        var payer: String
        var bedText: String
        var attemptsText: String
        var minimumText: String
        var floorValue: String
        var statusLabel: String

        init(codeText: String, nameText: String, startsAt: String, channelText: String, payer: String, bedText: String, attemptsText: String, minimumText: String, floorValue: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.startsAt = startsAt
            self.channelText = channelText
            self.payer = payer
            self.bedText = bedText
            self.attemptsText = attemptsText
            self.minimumText = minimumText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryPreferenceView(_ item: InventoryPreference) -> InventoryPreferenceView {
        return InventoryPreferenceView(
            codeText: item.code,
            nameText: item.name,
            startsAt: String(item.startsAt),
            channelText: item.channel,
            payer: item.payer,
            bedText: Kit.Text.truncate(item.bed, limit: 120),
            attemptsText: String(item.attempts),
            minimumText: String(format: "%.2f", item.minimum),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryPreferenceViews(_ items: [InventoryPreference]) -> [InventoryPreferenceView] {
        var views: [InventoryPreferenceView] = []
        for item in items {
            views.append(toInventoryPreferenceView(item))
        }
        return views
    }

    static func sumInventoryPreferenceView(_ view: InventoryPreferenceView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedAttempts) + parsedMinimum
    }
}
