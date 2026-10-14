import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a regional isolation policy.
    final class RegionalIsolationPolicyView {
        var code: String
        var labelText: String
        var score: String
        var facility: String
        var payerText: String
        var archived: String
        var cost: String
        var activeText: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, labelText: String, score: String, facility: String, payerText: String, archived: String, cost: String, activeText: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.score = score
            self.facility = facility
            self.payerText = payerText
            self.archived = archived
            self.cost = cost
            self.activeText = activeText
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalIsolationPolicyView(_ item: RegionalIsolationPolicy) -> RegionalIsolationPolicyView {
        return RegionalIsolationPolicyView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            score: String(format: "%.2f", item.score),
            facility: item.facility,
            payerText: Kit.Text.truncate(item.payer, limit: 64),
            archived: "\(item.archived)",
            cost: String(format: "%.2f", item.cost),
            activeText: "\(item.active)",
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalIsolationPolicyViews(_ items: [RegionalIsolationPolicy]) -> [RegionalIsolationPolicyView] {
        var views: [RegionalIsolationPolicyView] = []
        for item in items {
            views.append(toRegionalIsolationPolicyView(item))
        }
        return views
    }

    static func sumRegionalIsolationPolicyView(_ view: RegionalIsolationPolicyView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedScore + parsedCost
    }
}
