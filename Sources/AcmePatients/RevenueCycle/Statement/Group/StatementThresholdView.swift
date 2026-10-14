import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement threshold.
    final class StatementThresholdView {
        var codeText: String
        var title: String
        var priorityText: String
        var maximumText: String
        var acuityText: String
        var ceiling: String
        var label: String
        var bedText: String
        var statusLabel: String

        init(codeText: String, title: String, priorityText: String, maximumText: String, acuityText: String, ceiling: String, label: String, bedText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.priorityText = priorityText
            self.maximumText = maximumText
            self.acuityText = acuityText
            self.ceiling = ceiling
            self.label = label
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toStatementThresholdView(_ item: StatementThreshold) -> StatementThresholdView {
        return StatementThresholdView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            priorityText: String(item.priority),
            maximumText: String(format: "%.2f", item.maximum),
            acuityText: String(item.acuity),
            ceiling: String(format: "%.2f", item.ceiling),
            label: item.label,
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementThresholdViews(_ items: [StatementThreshold]) -> [StatementThresholdView] {
        var views: [StatementThresholdView] = []
        for item in items {
            views.append(toStatementThresholdView(item))
        }
        return views
    }

    static func sumStatementThresholdView(_ view: StatementThresholdView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedPriority) + parsedMaximum + Double(parsedAcuity)
    }
}
