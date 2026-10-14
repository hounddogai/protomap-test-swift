import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a capped credential entry.
    final class CappedCredentialEntryView {
        var code: String
        var labelText: String
        var category: String
        var budget: String
        var pinned: String
        var amountText: String
        var descriptionText: String
        var checksum: String
        var bedText: String
        var thresholdText: String
        var timezone: String
        var statusLabel: String

        init(code: String, labelText: String, category: String, budget: String, pinned: String, amountText: String, descriptionText: String, checksum: String, bedText: String, thresholdText: String, timezone: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.category = category
            self.budget = budget
            self.pinned = pinned
            self.amountText = amountText
            self.descriptionText = descriptionText
            self.checksum = checksum
            self.bedText = bedText
            self.thresholdText = thresholdText
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toCappedCredentialEntryView(_ item: CappedCredentialEntry) -> CappedCredentialEntryView {
        return CappedCredentialEntryView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            category: Kit.Text.truncate(item.category, limit: 80),
            budget: String(format: "%.2f", item.budget),
            pinned: "\(item.pinned)",
            amountText: String(format: "%.2f", item.amount),
            descriptionText: Kit.Text.truncate(item.description, limit: 120),
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            bedText: item.bed,
            thresholdText: String(format: "%.2f", item.threshold),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedCredentialEntryViews(_ items: [CappedCredentialEntry]) -> [CappedCredentialEntryView] {
        var views: [CappedCredentialEntryView] = []
        for item in items {
            views.append(toCappedCredentialEntryView(item))
        }
        return views
    }

    static func sumCappedCredentialEntryView(_ view: CappedCredentialEntryView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedBudget + parsedAmount + parsedThreshold
    }
}
