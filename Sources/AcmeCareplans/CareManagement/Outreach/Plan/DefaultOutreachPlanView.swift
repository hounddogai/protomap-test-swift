import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default outreach plan.
    final class DefaultOutreachPlanView {
        var code: String
        var titleText: String
        var summary: String
        var phone: String
        var pinnedText: String
        var revision: String
        var statusLabel: String

        init(code: String, titleText: String, summary: String, phone: String, pinnedText: String, revision: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.summary = summary
            self.phone = phone
            self.pinnedText = pinnedText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultOutreachPlanView(_ item: DefaultOutreachPlan) -> DefaultOutreachPlanView {
        return DefaultOutreachPlanView(
            code: item.code,
            titleText: item.title,
            summary: item.summary,
            phone: item.phone,
            pinnedText: "\(item.pinned)",
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultOutreachPlanViews(_ items: [DefaultOutreachPlan]) -> [DefaultOutreachPlanView] {
        var views: [DefaultOutreachPlanView] = []
        for item in items {
            views.append(toDefaultOutreachPlanView(item))
        }
        return views
    }

    static func sumDefaultOutreachPlanView(_ view: DefaultOutreachPlanView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
