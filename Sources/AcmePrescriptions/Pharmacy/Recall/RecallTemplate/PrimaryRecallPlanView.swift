import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary recall plan.
    final class PrimaryRecallPlanView {
        var codeText: String
        var label: String
        var priority: String
        var region: String
        var dosageMg: String
        var createdAt: String
        var statusLabel: String

        init(codeText: String, label: String, priority: String, region: String, dosageMg: String, createdAt: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.priority = priority
            self.region = region
            self.dosageMg = dosageMg
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryRecallPlanView(_ item: PrimaryRecallPlan) -> PrimaryRecallPlanView {
        return PrimaryRecallPlanView(
            codeText: item.code,
            label: item.label,
            priority: String(item.priority),
            region: item.region,
            dosageMg: String(format: "%.2f", item.dosageMg),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryRecallPlanViews(_ items: [PrimaryRecallPlan]) -> [PrimaryRecallPlanView] {
        var views: [PrimaryRecallPlanView] = []
        for item in items {
            views.append(toPrimaryRecallPlanView(item))
        }
        return views
    }

    static func sumPrimaryRecallPlanView(_ view: PrimaryRecallPlanView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedPriority) + parsedDosageMg + Double(parsedCreatedAt)
    }
}
