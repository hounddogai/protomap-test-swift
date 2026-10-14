import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan audit.
    final class DischargePlanAuditView {
        var code: String
        var title: String
        var attempts: String
        var name: String
        var cost: String
        var statusLabel: String

        init(code: String, title: String, attempts: String, name: String, cost: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.name = name
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanAuditView(_ item: DischargePlanAudit) -> DischargePlanAuditView {
        return DischargePlanAuditView(
            code: item.code,
            title: item.title,
            attempts: String(item.attempts),
            name: item.name,
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanAuditViews(_ items: [DischargePlanAudit]) -> [DischargePlanAuditView] {
        var views: [DischargePlanAuditView] = []
        for item in items {
            views.append(toDischargePlanAuditView(item))
        }
        return views
    }

    static func sumDischargePlanAuditView(_ view: DischargePlanAuditView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedAttempts) + parsedCost
    }
}
