import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement preference.
    final class StatementPreferenceView {
        var codeText: String
        var nameText: String
        var thresholdText: String
        var refills: String
        var revision: String
        var margin: String
        var statusLabel: String

        init(codeText: String, nameText: String, thresholdText: String, refills: String, revision: String, margin: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.thresholdText = thresholdText
            self.refills = refills
            self.revision = revision
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toStatementPreferenceView(_ item: StatementPreference) -> StatementPreferenceView {
        return StatementPreferenceView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            thresholdText: String(format: "%.2f", item.threshold),
            refills: String(item.refills),
            revision: String(item.revision),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementPreferenceViews(_ items: [StatementPreference]) -> [StatementPreferenceView] {
        var views: [StatementPreferenceView] = []
        for item in items {
            views.append(toStatementPreferenceView(item))
        }
        return views
    }

    static func sumStatementPreferenceView(_ view: StatementPreferenceView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedThreshold + Double(parsedRefills) + Double(parsedRevision)
    }
}
