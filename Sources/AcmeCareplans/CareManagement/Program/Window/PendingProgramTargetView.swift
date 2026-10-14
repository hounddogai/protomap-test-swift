import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending program target.
    final class PendingProgramTargetView {
        var code: String
        var name: String
        var costText: String
        var discount: String
        var archived: String
        var statusLabel: String

        init(code: String, name: String, costText: String, discount: String, archived: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.costText = costText
            self.discount = discount
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toPendingProgramTargetView(_ item: PendingProgramTarget) -> PendingProgramTargetView {
        return PendingProgramTargetView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            costText: String(format: "%.2f", item.cost),
            discount: String(format: "%.2f", item.discount),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingProgramTargetViews(_ items: [PendingProgramTarget]) -> [PendingProgramTargetView] {
        var views: [PendingProgramTargetView] = []
        for item in items {
            views.append(toPendingProgramTargetView(item))
        }
        return views
    }

    static func sumPendingProgramTargetView(_ view: PendingProgramTargetView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedCost + parsedDiscount
    }
}
