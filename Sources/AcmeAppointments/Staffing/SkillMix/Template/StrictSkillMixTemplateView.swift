import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict skill mix template.
    final class StrictSkillMixTemplateView {
        var code: String
        var title: String
        var amount: String
        var quantity: String
        var durationMinutes: String
        var contactEmail: String
        var attempts: String
        var floorValue: String
        var revision: String
        var margin: String
        var ratio: String
        var statusLabel: String

        init(code: String, title: String, amount: String, quantity: String, durationMinutes: String, contactEmail: String, attempts: String, floorValue: String, revision: String, margin: String, ratio: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.amount = amount
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.contactEmail = contactEmail
            self.attempts = attempts
            self.floorValue = floorValue
            self.revision = revision
            self.margin = margin
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toStrictSkillMixTemplateView(_ item: StrictSkillMixTemplate) -> StrictSkillMixTemplateView {
        return StrictSkillMixTemplateView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            amount: String(format: "%.2f", item.amount),
            quantity: String(item.quantity),
            durationMinutes: String(item.durationMinutes),
            contactEmail: item.contactEmail,
            attempts: String(item.attempts),
            floorValue: String(format: "%.2f", item.floorValue),
            revision: String(item.revision),
            margin: String(format: "%.2f", item.margin),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictSkillMixTemplateViews(_ items: [StrictSkillMixTemplate]) -> [StrictSkillMixTemplateView] {
        var views: [StrictSkillMixTemplateView] = []
        for item in items {
            views.append(toStrictSkillMixTemplateView(item))
        }
        return views
    }

    static func sumStrictSkillMixTemplateView(_ view: StrictSkillMixTemplateView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedAmount + Double(parsedQuantity) + Double(parsedDurationMinutes)
    }
}
