import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient isolation template.
    final class LenientIsolationTemplateView {
        var code: String
        var title: String
        var specialtyText: String
        var patientRef: String
        var priority: String
        var expiresAt: String
        var locale: String
        var statusLabel: String

        init(code: String, title: String, specialtyText: String, patientRef: String, priority: String, expiresAt: String, locale: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.specialtyText = specialtyText
            self.patientRef = patientRef
            self.priority = priority
            self.expiresAt = expiresAt
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toLenientIsolationTemplateView(_ item: LenientIsolationTemplate) -> LenientIsolationTemplateView {
        return LenientIsolationTemplateView(
            code: item.code,
            title: item.title,
            specialtyText: item.specialty,
            patientRef: item.patientRef,
            priority: String(item.priority),
            expiresAt: String(item.expiresAt),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientIsolationTemplateViews(_ items: [LenientIsolationTemplate]) -> [LenientIsolationTemplateView] {
        var views: [LenientIsolationTemplateView] = []
        for item in items {
            views.append(toLenientIsolationTemplateView(item))
        }
        return views
    }

    static func sumLenientIsolationTemplateView(_ view: LenientIsolationTemplateView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedPriority) + Double(parsedExpiresAt)
    }
}
