import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy reference range profile.
    final class LegacyReferenceRangeProfileView {
        var code: String
        var labelText: String
        var budget: String
        var summary: String
        var retriesText: String
        var statusLabel: String

        init(code: String, labelText: String, budget: String, summary: String, retriesText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.budget = budget
            self.summary = summary
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyReferenceRangeProfileView(_ item: LegacyReferenceRangeProfile) -> LegacyReferenceRangeProfileView {
        return LegacyReferenceRangeProfileView(
            code: item.code,
            labelText: item.label,
            budget: String(format: "%.2f", item.budget),
            summary: Kit.Text.truncate(item.summary, limit: 80),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyReferenceRangeProfileViews(_ items: [LegacyReferenceRangeProfile]) -> [LegacyReferenceRangeProfileView] {
        var views: [LegacyReferenceRangeProfileView] = []
        for item in items {
            views.append(toLegacyReferenceRangeProfileView(item))
        }
        return views
    }

    static func sumLegacyReferenceRangeProfileView(_ view: LegacyReferenceRangeProfileView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedBudget + Double(parsedRetries)
    }
}
