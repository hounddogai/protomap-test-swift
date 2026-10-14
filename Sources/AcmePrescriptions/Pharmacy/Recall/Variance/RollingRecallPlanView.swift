import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling recall plan.
    final class RollingRecallPlanView {
        var codeText: String
        var name: String
        var updatedAt: String
        var dosageMg: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, name: String, updatedAt: String, dosageMg: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.updatedAt = updatedAt
            self.dosageMg = dosageMg
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toRollingRecallPlanView(_ item: RollingRecallPlan) -> RollingRecallPlanView {
        return RollingRecallPlanView(
            codeText: item.code,
            name: item.name,
            updatedAt: String(item.updatedAt),
            dosageMg: String(format: "%.2f", item.dosageMg),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingRecallPlanViews(_ items: [RollingRecallPlan]) -> [RollingRecallPlanView] {
        var views: [RollingRecallPlanView] = []
        for item in items {
            views.append(toRollingRecallPlanView(item))
        }
        return views
    }

    static func sumRollingRecallPlanView(_ view: RollingRecallPlanView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedUpdatedAt) + parsedDosageMg + Double(parsedExpiresAt)
    }
}
