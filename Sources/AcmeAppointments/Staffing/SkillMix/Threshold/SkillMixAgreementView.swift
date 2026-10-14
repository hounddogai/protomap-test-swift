import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix agreement.
    final class SkillMixAgreementView {
        var codeText: String
        var title: String
        var active: String
        var version: String
        var graceDays: String
        var cost: String
        var statusLabel: String

        init(codeText: String, title: String, active: String, version: String, graceDays: String, cost: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.active = active
            self.version = version
            self.graceDays = graceDays
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixAgreementView(_ item: SkillMixAgreement) -> SkillMixAgreementView {
        return SkillMixAgreementView(
            codeText: item.code,
            title: item.title,
            active: "\(item.active)",
            version: String(item.version),
            graceDays: String(item.graceDays),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixAgreementViews(_ items: [SkillMixAgreement]) -> [SkillMixAgreementView] {
        var views: [SkillMixAgreementView] = []
        for item in items {
            views.append(toSkillMixAgreementView(item))
        }
        return views
    }

    static func sumSkillMixAgreementView(_ view: SkillMixAgreementView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedVersion) + Double(parsedGraceDays) + parsedCost
    }
}
