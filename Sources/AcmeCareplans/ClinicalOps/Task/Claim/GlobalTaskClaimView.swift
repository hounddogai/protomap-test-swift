import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a global task claim.
    final class GlobalTaskClaimView {
        var code: String
        var labelText: String
        var name: String
        var cost: String
        var createdAt: String
        var statusLabel: String

        init(code: String, labelText: String, name: String, cost: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.name = name
            self.cost = cost
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalTaskClaimView(_ item: GlobalTaskClaim) -> GlobalTaskClaimView {
        return GlobalTaskClaimView(
            code: item.code,
            labelText: item.label,
            name: Kit.Text.truncate(item.name, limit: 64),
            cost: String(format: "%.2f", item.cost),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalTaskClaimViews(_ items: [GlobalTaskClaim]) -> [GlobalTaskClaimView] {
        var views: [GlobalTaskClaimView] = []
        for item in items {
            views.append(toGlobalTaskClaimView(item))
        }
        return views
    }

    static func sumGlobalTaskClaimView(_ view: GlobalTaskClaimView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedCost + Double(parsedCreatedAt)
    }
}
