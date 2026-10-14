import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive overtime budget.
    final class AdaptiveOvertimeBudgetView {
        var code: String
        var labelText: String
        var createdAt: String
        var clinicianID: String
        var notes: String
        var reviewer: String
        var threshold: String
        var statusLabel: String

        init(code: String, labelText: String, createdAt: String, clinicianID: String, notes: String, reviewer: String, threshold: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.createdAt = createdAt
            self.clinicianID = clinicianID
            self.notes = notes
            self.reviewer = reviewer
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveOvertimeBudgetView(_ item: AdaptiveOvertimeBudget) -> AdaptiveOvertimeBudgetView {
        return AdaptiveOvertimeBudgetView(
            code: item.code,
            labelText: item.label,
            createdAt: String(item.createdAt),
            clinicianID: item.clinicianID,
            notes: Kit.Text.truncate(item.notes, limit: 40),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveOvertimeBudgetViews(_ items: [AdaptiveOvertimeBudget]) -> [AdaptiveOvertimeBudgetView] {
        var views: [AdaptiveOvertimeBudgetView] = []
        for item in items {
            views.append(toAdaptiveOvertimeBudgetView(item))
        }
        return views
    }

    static func sumAdaptiveOvertimeBudgetView(_ view: AdaptiveOvertimeBudgetView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedCreatedAt) + parsedThreshold
    }
}
