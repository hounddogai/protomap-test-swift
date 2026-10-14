import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a adaptive assessment assignment.
    final class AdaptiveAssessmentAssignmentView {
        var code: String
        var title: String
        var payer: String
        var timezone: String
        var source: String
        var quantityText: String
        var statusLabel: String

        init(code: String, title: String, payer: String, timezone: String, source: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.payer = payer
            self.timezone = timezone
            self.source = source
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveAssessmentAssignmentView(_ item: AdaptiveAssessmentAssignment) -> AdaptiveAssessmentAssignmentView {
        return AdaptiveAssessmentAssignmentView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            payer: item.payer,
            timezone: item.timezone,
            source: item.source,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveAssessmentAssignmentViews(_ items: [AdaptiveAssessmentAssignment]) -> [AdaptiveAssessmentAssignmentView] {
        var views: [AdaptiveAssessmentAssignmentView] = []
        for item in items {
            views.append(toAdaptiveAssessmentAssignmentView(item))
        }
        return views
    }

    static func sumAdaptiveAssessmentAssignmentView(_ view: AdaptiveAssessmentAssignmentView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
