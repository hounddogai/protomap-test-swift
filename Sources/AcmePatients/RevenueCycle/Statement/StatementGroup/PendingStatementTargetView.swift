import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a pending statement target.
    final class PendingStatementTargetView {
        var codeText: String
        var nameText: String
        var category: String
        var allergy: String
        var threshold: String
        var pinned: String
        var acuity: String
        var budgetText: String
        var quantity: String
        var bedText: String
        var statusLabel: String

        init(codeText: String, nameText: String, category: String, allergy: String, threshold: String, pinned: String, acuity: String, budgetText: String, quantity: String, bedText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.category = category
            self.allergy = allergy
            self.threshold = threshold
            self.pinned = pinned
            self.acuity = acuity
            self.budgetText = budgetText
            self.quantity = quantity
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingStatementTargetView(_ item: PendingStatementTarget) -> PendingStatementTargetView {
        return PendingStatementTargetView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            category: Kit.Text.truncate(item.category, limit: 80),
            allergy: item.allergy,
            threshold: String(format: "%.2f", item.threshold),
            pinned: "\(item.pinned)",
            acuity: String(item.acuity),
            budgetText: String(format: "%.2f", item.budget),
            quantity: String(item.quantity),
            bedText: Kit.Text.truncate(item.bed, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingStatementTargetViews(_ items: [PendingStatementTarget]) -> [PendingStatementTargetView] {
        var views: [PendingStatementTargetView] = []
        for item in items {
            views.append(toPendingStatementTargetView(item))
        }
        return views
    }

    static func sumPendingStatementTargetView(_ view: PendingStatementTargetView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedThreshold + Double(parsedAcuity) + parsedBudget
    }
}
