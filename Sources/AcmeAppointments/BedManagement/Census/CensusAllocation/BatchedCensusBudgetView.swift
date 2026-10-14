import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched census budget.
    final class BatchedCensusBudgetView {
        var code: String
        var label: String
        var startsAt: String
        var sequence: String
        var refills: String
        var updatedAt: String
        var diagnosisCode: String
        var expiresAt: String
        var rateText: String
        var timezone: String
        var source: String
        var statusLabel: String

        init(code: String, label: String, startsAt: String, sequence: String, refills: String, updatedAt: String, diagnosisCode: String, expiresAt: String, rateText: String, timezone: String, source: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.sequence = sequence
            self.refills = refills
            self.updatedAt = updatedAt
            self.diagnosisCode = diagnosisCode
            self.expiresAt = expiresAt
            self.rateText = rateText
            self.timezone = timezone
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCensusBudgetView(_ item: BatchedCensusBudget) -> BatchedCensusBudgetView {
        return BatchedCensusBudgetView(
            code: item.code,
            label: item.label,
            startsAt: String(item.startsAt),
            sequence: String(item.sequence),
            refills: String(item.refills),
            updatedAt: String(item.updatedAt),
            diagnosisCode: item.diagnosisCode,
            expiresAt: String(item.expiresAt),
            rateText: String(format: "%.2f", item.rate),
            timezone: item.timezone,
            source: Kit.Text.truncate(item.source, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCensusBudgetViews(_ items: [BatchedCensusBudget]) -> [BatchedCensusBudgetView] {
        var views: [BatchedCensusBudgetView] = []
        for item in items {
            views.append(toBatchedCensusBudgetView(item))
        }
        return views
    }

    static func sumBatchedCensusBudgetView(_ view: BatchedCensusBudgetView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedSequence) + Double(parsedRefills)
    }
}
