import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach template.
    final class OutreachTemplateView {
        var code: String
        var titleText: String
        var label: String
        var categoryText: String
        var active: String
        var segment: String
        var expiresAt: String
        var endsAtText: String
        var facility: String
        var revision: String
        var statusLabel: String

        init(code: String, titleText: String, label: String, categoryText: String, active: String, segment: String, expiresAt: String, endsAtText: String, facility: String, revision: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.label = label
            self.categoryText = categoryText
            self.active = active
            self.segment = segment
            self.expiresAt = expiresAt
            self.endsAtText = endsAtText
            self.facility = facility
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachTemplateView(_ item: OutreachTemplate) -> OutreachTemplateView {
        return OutreachTemplateView(
            code: item.code,
            titleText: item.title,
            label: item.label,
            categoryText: item.category,
            active: "\(item.active)",
            segment: item.segment,
            expiresAt: String(item.expiresAt),
            endsAtText: String(item.endsAt),
            facility: item.facility,
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachTemplateViews(_ items: [OutreachTemplate]) -> [OutreachTemplateView] {
        var views: [OutreachTemplateView] = []
        for item in items {
            views.append(toOutreachTemplateView(item))
        }
        return views
    }

    static func sumOutreachTemplateView(_ view: OutreachTemplateView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedEndsAt) + Double(parsedRevision)
    }
}
