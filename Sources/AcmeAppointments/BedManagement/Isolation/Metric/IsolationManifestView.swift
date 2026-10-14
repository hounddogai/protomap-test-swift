import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation manifest.
    final class IsolationManifestView {
        var codeText: String
        var label: String
        var limit: String
        var discountText: String
        var budgetText: String
        var statusLabel: String

        init(codeText: String, label: String, limit: String, discountText: String, budgetText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.limit = limit
            self.discountText = discountText
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationManifestView(_ item: IsolationManifest) -> IsolationManifestView {
        return IsolationManifestView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            limit: String(item.limit),
            discountText: String(format: "%.2f", item.discount),
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationManifestViews(_ items: [IsolationManifest]) -> [IsolationManifestView] {
        var views: [IsolationManifestView] = []
        for item in items {
            views.append(toIsolationManifestView(item))
        }
        return views
    }

    static func sumIsolationManifestView(_ view: IsolationManifestView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedLimit) + parsedDiscount + parsedBudget
    }
}
