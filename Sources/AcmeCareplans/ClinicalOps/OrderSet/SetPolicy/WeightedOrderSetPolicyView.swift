import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a weighted order set policy.
    final class WeightedOrderSetPolicyView {
        var code: String
        var labelText: String
        var graceDays: String
        var ceiling: String
        var procedureCode: String
        var retries: String
        var payer: String
        var bedText: String
        var priority: String
        var endsAt: String
        var attempts: String
        var statusLabel: String

        init(code: String, labelText: String, graceDays: String, ceiling: String, procedureCode: String, retries: String, payer: String, bedText: String, priority: String, endsAt: String, attempts: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.graceDays = graceDays
            self.ceiling = ceiling
            self.procedureCode = procedureCode
            self.retries = retries
            self.payer = payer
            self.bedText = bedText
            self.priority = priority
            self.endsAt = endsAt
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedOrderSetPolicyView(_ item: WeightedOrderSetPolicy) -> WeightedOrderSetPolicyView {
        return WeightedOrderSetPolicyView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            graceDays: String(item.graceDays),
            ceiling: String(format: "%.2f", item.ceiling),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            retries: String(item.retries),
            payer: item.payer,
            bedText: Kit.Text.truncate(item.bed, limit: 40),
            priority: String(item.priority),
            endsAt: String(item.endsAt),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedOrderSetPolicyViews(_ items: [WeightedOrderSetPolicy]) -> [WeightedOrderSetPolicyView] {
        var views: [WeightedOrderSetPolicyView] = []
        for item in items {
            views.append(toWeightedOrderSetPolicyView(item))
        }
        return views
    }

    static func sumWeightedOrderSetPolicyView(_ view: WeightedOrderSetPolicyView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedGraceDays) + parsedCeiling + Double(parsedRetries)
    }
}
