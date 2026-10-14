import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach rule.
    final class OutreachRuleView {
        var code: String
        var title: String
        var revisionText: String
        var wardText: String
        var acuity: String
        var externalRef: String
        var version: String
        var statusLabel: String

        init(code: String, title: String, revisionText: String, wardText: String, acuity: String, externalRef: String, version: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revisionText = revisionText
            self.wardText = wardText
            self.acuity = acuity
            self.externalRef = externalRef
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachRuleView(_ item: OutreachRule) -> OutreachRuleView {
        return OutreachRuleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            revisionText: String(item.revision),
            wardText: Kit.Text.truncate(item.ward, limit: 64),
            acuity: String(item.acuity),
            externalRef: item.externalRef,
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachRuleViews(_ items: [OutreachRule]) -> [OutreachRuleView] {
        var views: [OutreachRuleView] = []
        for item in items {
            views.append(toOutreachRuleView(item))
        }
        return views
    }

    static func sumOutreachRuleView(_ view: OutreachRuleView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedRevision) + Double(parsedAcuity) + Double(parsedVersion)
    }
}
