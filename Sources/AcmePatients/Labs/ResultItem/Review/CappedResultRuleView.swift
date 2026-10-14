import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped result rule.
    final class CappedResultRuleView {
        var code: String
        var nameText: String
        var startsAt: String
        var source: String
        var approvedText: String
        var versionText: String
        var revisionText: String
        var windowDaysText: String
        var category: String
        var patientRef: String
        var threshold: String
        var statusLabel: String

        init(code: String, nameText: String, startsAt: String, source: String, approvedText: String, versionText: String, revisionText: String, windowDaysText: String, category: String, patientRef: String, threshold: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.startsAt = startsAt
            self.source = source
            self.approvedText = approvedText
            self.versionText = versionText
            self.revisionText = revisionText
            self.windowDaysText = windowDaysText
            self.category = category
            self.patientRef = patientRef
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toCappedResultRuleView(_ item: CappedResultRule) -> CappedResultRuleView {
        return CappedResultRuleView(
            code: item.code,
            nameText: item.name,
            startsAt: String(item.startsAt),
            source: item.source,
            approvedText: "\(item.approved)",
            versionText: String(item.version),
            revisionText: String(item.revision),
            windowDaysText: String(item.windowDays),
            category: Kit.Text.truncate(item.category, limit: 40),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedResultRuleViews(_ items: [CappedResultRule]) -> [CappedResultRuleView] {
        var views: [CappedResultRuleView] = []
        for item in items {
            views.append(toCappedResultRuleView(item))
        }
        return views
    }

    static func sumCappedResultRuleView(_ view: CappedResultRuleView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedVersion) + Double(parsedRevision)
    }
}
