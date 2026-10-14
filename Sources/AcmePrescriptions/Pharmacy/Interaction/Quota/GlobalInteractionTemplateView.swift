import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a global interaction template.
    final class GlobalInteractionTemplateView {
        var code: String
        var title: String
        var createdAt: String
        var visitMinutesText: String
        var attempts: String
        var statusLabel: String

        init(code: String, title: String, createdAt: String, visitMinutesText: String, attempts: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.visitMinutesText = visitMinutesText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalInteractionTemplateView(_ item: GlobalInteractionTemplate) -> GlobalInteractionTemplateView {
        return GlobalInteractionTemplateView(
            code: item.code,
            title: item.title,
            createdAt: String(item.createdAt),
            visitMinutesText: String(item.visitMinutes),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalInteractionTemplateViews(_ items: [GlobalInteractionTemplate]) -> [GlobalInteractionTemplateView] {
        var views: [GlobalInteractionTemplateView] = []
        for item in items {
            views.append(toGlobalInteractionTemplateView(item))
        }
        return views
    }

    static func sumGlobalInteractionTemplateView(_ view: GlobalInteractionTemplateView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedVisitMinutes) + Double(parsedAttempts)
    }
}
