import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a scheduled inventory baseline.
    final class ScheduledInventoryBaselineView {
        var code: String
        var nameText: String
        var budget: String
        var revisionText: String
        var dosageMg: String
        var channel: String
        var currency: String
        var retries: String
        var statusLabel: String

        init(code: String, nameText: String, budget: String, revisionText: String, dosageMg: String, channel: String, currency: String, retries: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.budget = budget
            self.revisionText = revisionText
            self.dosageMg = dosageMg
            self.channel = channel
            self.currency = currency
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledInventoryBaselineView(_ item: ScheduledInventoryBaseline) -> ScheduledInventoryBaselineView {
        return ScheduledInventoryBaselineView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: Kit.Text.truncate(item.name, limit: 80),
            budget: String(format: "%.2f", item.budget),
            revisionText: String(item.revision),
            dosageMg: String(format: "%.2f", item.dosageMg),
            channel: Kit.Text.truncate(item.channel, limit: 80),
            currency: item.currency,
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledInventoryBaselineViews(_ items: [ScheduledInventoryBaseline]) -> [ScheduledInventoryBaselineView] {
        var views: [ScheduledInventoryBaselineView] = []
        for item in items {
            views.append(toScheduledInventoryBaselineView(item))
        }
        return views
    }

    static func sumScheduledInventoryBaselineView(_ view: ScheduledInventoryBaselineView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedBudget + Double(parsedRevision) + parsedDosageMg
    }
}
