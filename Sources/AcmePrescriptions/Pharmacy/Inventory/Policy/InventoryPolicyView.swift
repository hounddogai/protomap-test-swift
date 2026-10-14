import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory policy.
    final class InventoryPolicyView {
        var code: String
        var nameText: String
        var timezoneText: String
        var durationMinutesText: String
        var checksumText: String
        var discount: String
        var reviewer: String
        var budget: String
        var archived: String
        var bedText: String
        var channel: String
        var statusLabel: String

        init(code: String, nameText: String, timezoneText: String, durationMinutesText: String, checksumText: String, discount: String, reviewer: String, budget: String, archived: String, bedText: String, channel: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.timezoneText = timezoneText
            self.durationMinutesText = durationMinutesText
            self.checksumText = checksumText
            self.discount = discount
            self.reviewer = reviewer
            self.budget = budget
            self.archived = archived
            self.bedText = bedText
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryPolicyView(_ item: InventoryPolicy) -> InventoryPolicyView {
        return InventoryPolicyView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            timezoneText: item.timezone,
            durationMinutesText: String(item.durationMinutes),
            checksumText: item.checksum,
            discount: String(format: "%.2f", item.discount),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            budget: String(format: "%.2f", item.budget),
            archived: "\(item.archived)",
            bedText: item.bed,
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryPolicyViews(_ items: [InventoryPolicy]) -> [InventoryPolicyView] {
        var views: [InventoryPolicyView] = []
        for item in items {
            views.append(toInventoryPolicyView(item))
        }
        return views
    }

    static func sumInventoryPolicyView(_ view: InventoryPolicyView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedDurationMinutes) + parsedDiscount + parsedBudget
    }
}
