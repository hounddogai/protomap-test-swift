import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending result rule.
    final class PendingResultRuleView {
        var codeText: String
        var name: String
        var procedureCode: String
        var active: String
        var ratioText: String
        var retries: String
        var statusLabel: String

        init(codeText: String, name: String, procedureCode: String, active: String, ratioText: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.procedureCode = procedureCode
            self.active = active
            self.ratioText = ratioText
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toPendingResultRuleView(_ item: PendingResultRule) -> PendingResultRuleView {
        return PendingResultRuleView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            procedureCode: item.procedureCode,
            active: "\(item.active)",
            ratioText: String(format: "%.2f", item.ratio),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingResultRuleViews(_ items: [PendingResultRule]) -> [PendingResultRuleView] {
        var views: [PendingResultRuleView] = []
        for item in items {
            views.append(toPendingResultRuleView(item))
        }
        return views
    }

    static func sumPendingResultRuleView(_ view: PendingResultRuleView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedRatio + Double(parsedRetries)
    }
}
