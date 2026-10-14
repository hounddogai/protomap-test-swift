import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a fallback alert override.
    final class FallbackAlertOverrideView {
        var code: String
        var titleText: String
        var notes: String
        var active: String
        var endsAtText: String
        var refills: String
        var attempts: String
        var archived: String
        var category: String
        var discount: String
        var statusLabel: String

        init(code: String, titleText: String, notes: String, active: String, endsAtText: String, refills: String, attempts: String, archived: String, category: String, discount: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.notes = notes
            self.active = active
            self.endsAtText = endsAtText
            self.refills = refills
            self.attempts = attempts
            self.archived = archived
            self.category = category
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackAlertOverrideView(_ item: FallbackAlertOverride) -> FallbackAlertOverrideView {
        return FallbackAlertOverrideView(
            code: item.code,
            titleText: item.title,
            notes: item.notes,
            active: "\(item.active)",
            endsAtText: String(item.endsAt),
            refills: String(item.refills),
            attempts: String(item.attempts),
            archived: "\(item.archived)",
            category: item.category,
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackAlertOverrideViews(_ items: [FallbackAlertOverride]) -> [FallbackAlertOverrideView] {
        var views: [FallbackAlertOverrideView] = []
        for item in items {
            views.append(toFallbackAlertOverrideView(item))
        }
        return views
    }

    static func sumFallbackAlertOverrideView(_ view: FallbackAlertOverrideView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedRefills) + Double(parsedAttempts)
    }
}
