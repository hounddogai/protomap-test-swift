import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan draft.
    final class AcuityPlanDraftView {
        var code: String
        var label: String
        var allergy: String
        var summary: String
        var bedText: String
        var nameText: String
        var acuityText: String
        var statusLabel: String

        init(code: String, label: String, allergy: String, summary: String, bedText: String, nameText: String, acuityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.summary = summary
            self.bedText = bedText
            self.nameText = nameText
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanDraftView(_ item: AcuityPlanDraft) -> AcuityPlanDraftView {
        return AcuityPlanDraftView(
            code: item.code,
            label: item.label,
            allergy: item.allergy,
            summary: Kit.Text.truncate(item.summary, limit: 40),
            bedText: Kit.Text.truncate(item.bed, limit: 40),
            nameText: Kit.Text.truncate(item.name, limit: 80),
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanDraftViews(_ items: [AcuityPlanDraft]) -> [AcuityPlanDraftView] {
        var views: [AcuityPlanDraftView] = []
        for item in items {
            views.append(toAcuityPlanDraftView(item))
        }
        return views
    }

    static func sumAcuityPlanDraftView(_ view: AcuityPlanDraftView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
