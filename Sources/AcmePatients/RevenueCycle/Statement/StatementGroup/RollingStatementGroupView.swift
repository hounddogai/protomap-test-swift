import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a rolling statement group.
    final class RollingStatementGroupView {
        var codeText: String
        var titleText: String
        var currency: String
        var ward: String
        var clinicianID: String
        var summary: String
        var acuity: String
        var version: String
        var statusLabel: String

        init(codeText: String, titleText: String, currency: String, ward: String, clinicianID: String, summary: String, acuity: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.currency = currency
            self.ward = ward
            self.clinicianID = clinicianID
            self.summary = summary
            self.acuity = acuity
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toRollingStatementGroupView(_ item: RollingStatementGroup) -> RollingStatementGroupView {
        return RollingStatementGroupView(
            codeText: item.code,
            titleText: item.title,
            currency: item.currency,
            ward: item.ward,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 80),
            summary: item.summary,
            acuity: String(item.acuity),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingStatementGroupViews(_ items: [RollingStatementGroup]) -> [RollingStatementGroupView] {
        var views: [RollingStatementGroupView] = []
        for item in items {
            views.append(toRollingStatementGroupView(item))
        }
        return views
    }

    static func sumRollingStatementGroupView(_ view: RollingStatementGroupView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedAcuity) + Double(parsedVersion)
    }
}
