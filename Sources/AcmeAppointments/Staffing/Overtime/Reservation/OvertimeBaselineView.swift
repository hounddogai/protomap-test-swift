import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime baseline.
    final class OvertimeBaselineView {
        var codeText: String
        var titleText: String
        var ward: String
        var summary: String
        var maximumText: String
        var reviewerText: String
        var budget: String
        var statusLabel: String

        init(codeText: String, titleText: String, ward: String, summary: String, maximumText: String, reviewerText: String, budget: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.ward = ward
            self.summary = summary
            self.maximumText = maximumText
            self.reviewerText = reviewerText
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeBaselineView(_ item: OvertimeBaseline) -> OvertimeBaselineView {
        return OvertimeBaselineView(
            codeText: item.code,
            titleText: item.title,
            ward: item.ward,
            summary: item.summary,
            maximumText: String(format: "%.2f", item.maximum),
            reviewerText: item.reviewer,
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeBaselineViews(_ items: [OvertimeBaseline]) -> [OvertimeBaselineView] {
        var views: [OvertimeBaselineView] = []
        for item in items {
            views.append(toOvertimeBaselineView(item))
        }
        return views
    }

    static func sumOvertimeBaselineView(_ view: OvertimeBaselineView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedMaximum + parsedBudget
    }
}
