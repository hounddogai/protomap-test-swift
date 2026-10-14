import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal ledger.
    final class GoalLedgerView {
        var codeText: String
        var name: String
        var checksumText: String
        var updatedAtText: String
        var cost: String
        var weight: String
        var wardText: String
        var locale: String
        var ratio: String
        var statusLabel: String

        init(codeText: String, name: String, checksumText: String, updatedAtText: String, cost: String, weight: String, wardText: String, locale: String, ratio: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.checksumText = checksumText
            self.updatedAtText = updatedAtText
            self.cost = cost
            self.weight = weight
            self.wardText = wardText
            self.locale = locale
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toGoalLedgerView(_ item: GoalLedger) -> GoalLedgerView {
        return GoalLedgerView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            checksumText: item.checksum,
            updatedAtText: String(item.updatedAt),
            cost: String(format: "%.2f", item.cost),
            weight: String(format: "%.2f", item.weight),
            wardText: item.ward,
            locale: Kit.Text.truncate(item.locale, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalLedgerViews(_ items: [GoalLedger]) -> [GoalLedgerView] {
        var views: [GoalLedgerView] = []
        for item in items {
            views.append(toGoalLedgerView(item))
        }
        return views
    }

    static func sumGoalLedgerView(_ view: GoalLedgerView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedUpdatedAt) + parsedCost + parsedWeight
    }
}
