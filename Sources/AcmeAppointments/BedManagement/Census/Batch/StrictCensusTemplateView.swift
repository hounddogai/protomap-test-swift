import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a strict census template.
    final class StrictCensusTemplateView {
        var codeText: String
        var title: String
        var retries: String
        var updatedAt: String
        var description: String
        var approved: String
        var visitMinutes: String
        var encounterIDText: String
        var locale: String
        var capacity: String
        var reviewer: String
        var statusLabel: String

        init(codeText: String, title: String, retries: String, updatedAt: String, description: String, approved: String, visitMinutes: String, encounterIDText: String, locale: String, capacity: String, reviewer: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.retries = retries
            self.updatedAt = updatedAt
            self.description = description
            self.approved = approved
            self.visitMinutes = visitMinutes
            self.encounterIDText = encounterIDText
            self.locale = locale
            self.capacity = capacity
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toStrictCensusTemplateView(_ item: StrictCensusTemplate) -> StrictCensusTemplateView {
        return StrictCensusTemplateView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            retries: String(item.retries),
            updatedAt: String(item.updatedAt),
            description: item.description,
            approved: "\(item.approved)",
            visitMinutes: String(item.visitMinutes),
            encounterIDText: item.encounterID,
            locale: item.locale,
            capacity: String(item.capacity),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictCensusTemplateViews(_ items: [StrictCensusTemplate]) -> [StrictCensusTemplateView] {
        var views: [StrictCensusTemplateView] = []
        for item in items {
            views.append(toStrictCensusTemplateView(item))
        }
        return views
    }

    static func sumStrictCensusTemplateView(_ view: StrictCensusTemplateView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedRetries) + Double(parsedUpdatedAt) + Double(parsedVisitMinutes)
    }
}
