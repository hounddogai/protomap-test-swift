import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a fallback handoff summary.
    final class FallbackHandoffSummaryView {
        var codeText: String
        var label: String
        var priorityText: String
        var description: String
        var createdAtText: String
        var rate: String
        var sequence: String
        var statusLabel: String

        init(codeText: String, label: String, priorityText: String, description: String, createdAtText: String, rate: String, sequence: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.priorityText = priorityText
            self.description = description
            self.createdAtText = createdAtText
            self.rate = rate
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackHandoffSummaryView(_ item: FallbackHandoffSummary) -> FallbackHandoffSummaryView {
        return FallbackHandoffSummaryView(
            codeText: item.code,
            label: item.label,
            priorityText: String(item.priority),
            description: item.description,
            createdAtText: String(item.createdAt),
            rate: String(format: "%.2f", item.rate),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackHandoffSummaryViews(_ items: [FallbackHandoffSummary]) -> [FallbackHandoffSummaryView] {
        var views: [FallbackHandoffSummaryView] = []
        for item in items {
            views.append(toFallbackHandoffSummaryView(item))
        }
        return views
    }

    static func sumFallbackHandoffSummaryView(_ view: FallbackHandoffSummaryView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedPriority) + Double(parsedCreatedAt) + parsedRate
    }
}
