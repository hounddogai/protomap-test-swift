import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback eligibility template.
    final class FallbackEligibilityTemplateView {
        var codeText: String
        var label: String
        var archived: String
        var clinicianID: String
        var margin: String
        var notesText: String
        var rate: String
        var dosageMg: String
        var descriptionText: String
        var statusLabel: String

        init(codeText: String, label: String, archived: String, clinicianID: String, margin: String, notesText: String, rate: String, dosageMg: String, descriptionText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.archived = archived
            self.clinicianID = clinicianID
            self.margin = margin
            self.notesText = notesText
            self.rate = rate
            self.dosageMg = dosageMg
            self.descriptionText = descriptionText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackEligibilityTemplateView(_ item: FallbackEligibilityTemplate) -> FallbackEligibilityTemplateView {
        return FallbackEligibilityTemplateView(
            codeText: item.code,
            label: item.label,
            archived: "\(item.archived)",
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            margin: String(format: "%.2f", item.margin),
            notesText: item.notes,
            rate: String(format: "%.2f", item.rate),
            dosageMg: String(format: "%.2f", item.dosageMg),
            descriptionText: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackEligibilityTemplateViews(_ items: [FallbackEligibilityTemplate]) -> [FallbackEligibilityTemplateView] {
        var views: [FallbackEligibilityTemplateView] = []
        for item in items {
            views.append(toFallbackEligibilityTemplateView(item))
        }
        return views
    }

    static func sumFallbackEligibilityTemplateView(_ view: FallbackEligibilityTemplateView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedMargin + parsedRate + parsedDosageMg
    }
}
