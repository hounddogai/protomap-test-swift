import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched outreach policy.
    final class BatchedOutreachPolicyView {
        var codeText: String
        var name: String
        var visible: String
        var minimum: String
        var pinned: String
        var budget: String
        var windowDays: String
        var createdAt: String
        var diagnosisCodeText: String
        var statusLabel: String

        init(codeText: String, name: String, visible: String, minimum: String, pinned: String, budget: String, windowDays: String, createdAt: String, diagnosisCodeText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.visible = visible
            self.minimum = minimum
            self.pinned = pinned
            self.budget = budget
            self.windowDays = windowDays
            self.createdAt = createdAt
            self.diagnosisCodeText = diagnosisCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedOutreachPolicyView(_ item: BatchedOutreachPolicy) -> BatchedOutreachPolicyView {
        return BatchedOutreachPolicyView(
            codeText: item.code,
            name: item.name,
            visible: "\(item.visible)",
            minimum: String(format: "%.2f", item.minimum),
            pinned: "\(item.pinned)",
            budget: String(format: "%.2f", item.budget),
            windowDays: String(item.windowDays),
            createdAt: String(item.createdAt),
            diagnosisCodeText: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedOutreachPolicyViews(_ items: [BatchedOutreachPolicy]) -> [BatchedOutreachPolicyView] {
        var views: [BatchedOutreachPolicyView] = []
        for item in items {
            views.append(toBatchedOutreachPolicyView(item))
        }
        return views
    }

    static func sumBatchedOutreachPolicyView(_ view: BatchedOutreachPolicyView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedMinimum + parsedBudget + Double(parsedWindowDays)
    }
}
