import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation rule.
    final class IsolationRuleView {
        var code: String
        var title: String
        var externalRefText: String
        var acuity: String
        var notesText: String
        var graceDays: String
        var retries: String
        var active: String
        var statusLabel: String

        init(code: String, title: String, externalRefText: String, acuity: String, notesText: String, graceDays: String, retries: String, active: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.externalRefText = externalRefText
            self.acuity = acuity
            self.notesText = notesText
            self.graceDays = graceDays
            self.retries = retries
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationRuleView(_ item: IsolationRule) -> IsolationRuleView {
        return IsolationRuleView(
            code: item.code,
            title: item.title,
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 40),
            acuity: String(item.acuity),
            notesText: Kit.Text.truncate(item.notes, limit: 64),
            graceDays: String(item.graceDays),
            retries: String(item.retries),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationRuleViews(_ items: [IsolationRule]) -> [IsolationRuleView] {
        var views: [IsolationRuleView] = []
        for item in items {
            views.append(toIsolationRuleView(item))
        }
        return views
    }

    static func sumIsolationRuleView(_ view: IsolationRuleView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedAcuity) + Double(parsedGraceDays) + Double(parsedRetries)
    }
}
