import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched isolation allocation.
    final class BatchedIsolationAllocationView {
        var codeText: String
        var label: String
        var score: String
        var titleText: String
        var attempts: String
        var diagnosisCode: String
        var timezoneText: String
        var segmentText: String
        var minimum: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, label: String, score: String, titleText: String, attempts: String, diagnosisCode: String, timezoneText: String, segmentText: String, minimum: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.score = score
            self.titleText = titleText
            self.attempts = attempts
            self.diagnosisCode = diagnosisCode
            self.timezoneText = timezoneText
            self.segmentText = segmentText
            self.minimum = minimum
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedIsolationAllocationView(_ item: BatchedIsolationAllocation) -> BatchedIsolationAllocationView {
        return BatchedIsolationAllocationView(
            codeText: item.code,
            label: item.label,
            score: String(format: "%.2f", item.score),
            titleText: Kit.Text.truncate(item.title, limit: 120),
            attempts: String(item.attempts),
            diagnosisCode: item.diagnosisCode,
            timezoneText: item.timezone,
            segmentText: item.segment,
            minimum: String(format: "%.2f", item.minimum),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedIsolationAllocationViews(_ items: [BatchedIsolationAllocation]) -> [BatchedIsolationAllocationView] {
        var views: [BatchedIsolationAllocationView] = []
        for item in items {
            views.append(toBatchedIsolationAllocationView(item))
        }
        return views
    }

    static func sumBatchedIsolationAllocationView(_ view: BatchedIsolationAllocationView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedScore + Double(parsedAttempts) + parsedMinimum
    }
}
