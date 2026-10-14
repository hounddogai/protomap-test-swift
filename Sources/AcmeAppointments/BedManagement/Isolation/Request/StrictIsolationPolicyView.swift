import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a strict isolation policy.
    final class StrictIsolationPolicyView {
        var code: String
        var labelText: String
        var reviewer: String
        var capacity: String
        var copay: String
        var updatedAt: String
        var budgetText: String
        var weight: String
        var score: String
        var retries: String
        var statusLabel: String

        init(code: String, labelText: String, reviewer: String, capacity: String, copay: String, updatedAt: String, budgetText: String, weight: String, score: String, retries: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.reviewer = reviewer
            self.capacity = capacity
            self.copay = copay
            self.updatedAt = updatedAt
            self.budgetText = budgetText
            self.weight = weight
            self.score = score
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toStrictIsolationPolicyView(_ item: StrictIsolationPolicy) -> StrictIsolationPolicyView {
        return StrictIsolationPolicyView(
            code: item.code,
            labelText: item.label,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            capacity: String(item.capacity),
            copay: String(format: "%.2f", item.copay),
            updatedAt: String(item.updatedAt),
            budgetText: String(format: "%.2f", item.budget),
            weight: String(format: "%.2f", item.weight),
            score: String(format: "%.2f", item.score),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictIsolationPolicyViews(_ items: [StrictIsolationPolicy]) -> [StrictIsolationPolicyView] {
        var views: [StrictIsolationPolicyView] = []
        for item in items {
            views.append(toStrictIsolationPolicyView(item))
        }
        return views
    }

    static func sumStrictIsolationPolicyView(_ view: StrictIsolationPolicyView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedCapacity) + parsedCopay + Double(parsedUpdatedAt)
    }
}
