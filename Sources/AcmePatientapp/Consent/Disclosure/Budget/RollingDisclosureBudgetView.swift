import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling disclosure budget.
    final class RollingDisclosureBudgetView {
        var code: String
        var label: String
        var pinnedText: String
        var startsAtText: String
        var priority: String
        var procedureCode: String
        var checksum: String
        var threshold: String
        var statusLabel: String

        init(code: String, label: String, pinnedText: String, startsAtText: String, priority: String, procedureCode: String, checksum: String, threshold: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.pinnedText = pinnedText
            self.startsAtText = startsAtText
            self.priority = priority
            self.procedureCode = procedureCode
            self.checksum = checksum
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toRollingDisclosureBudgetView(_ item: RollingDisclosureBudget) -> RollingDisclosureBudgetView {
        return RollingDisclosureBudgetView(
            code: item.code,
            label: item.label,
            pinnedText: "\(item.pinned)",
            startsAtText: String(item.startsAt),
            priority: String(item.priority),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            checksum: Kit.Text.truncate(item.checksum, limit: 64),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingDisclosureBudgetViews(_ items: [RollingDisclosureBudget]) -> [RollingDisclosureBudgetView] {
        var views: [RollingDisclosureBudgetView] = []
        for item in items {
            views.append(toRollingDisclosureBudgetView(item))
        }
        return views
    }

    static func sumRollingDisclosureBudgetView(_ view: RollingDisclosureBudgetView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedPriority) + parsedThreshold
    }
}
