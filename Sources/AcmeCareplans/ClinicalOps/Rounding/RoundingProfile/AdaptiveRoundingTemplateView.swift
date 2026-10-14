import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a adaptive rounding template.
    final class AdaptiveRoundingTemplateView {
        var codeText: String
        var name: String
        var acuityText: String
        var durationMinutes: String
        var approved: String
        var startsAt: String
        var statusLabel: String

        init(codeText: String, name: String, acuityText: String, durationMinutes: String, approved: String, startsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.acuityText = acuityText
            self.durationMinutes = durationMinutes
            self.approved = approved
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveRoundingTemplateView(_ item: AdaptiveRoundingTemplate) -> AdaptiveRoundingTemplateView {
        return AdaptiveRoundingTemplateView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 64),
            acuityText: String(item.acuity),
            durationMinutes: String(item.durationMinutes),
            approved: "\(item.approved)",
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveRoundingTemplateViews(_ items: [AdaptiveRoundingTemplate]) -> [AdaptiveRoundingTemplateView] {
        var views: [AdaptiveRoundingTemplateView] = []
        for item in items {
            views.append(toAdaptiveRoundingTemplateView(item))
        }
        return views
    }

    static func sumAdaptiveRoundingTemplateView(_ view: AdaptiveRoundingTemplateView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedAcuity) + Double(parsedDurationMinutes) + Double(parsedStartsAt)
    }
}
