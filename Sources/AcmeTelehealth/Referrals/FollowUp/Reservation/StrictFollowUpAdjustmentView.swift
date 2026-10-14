import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a strict follow up adjustment.
    final class StrictFollowUpAdjustmentView {
        var codeText: String
        var label: String
        var regionText: String
        var specialtyText: String
        var createdAt: String
        var approvedText: String
        var diagnosisCodeText: String
        var encounterID: String
        var visible: String
        var allergy: String
        var summary: String
        var statusLabel: String

        init(codeText: String, label: String, regionText: String, specialtyText: String, createdAt: String, approvedText: String, diagnosisCodeText: String, encounterID: String, visible: String, allergy: String, summary: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.regionText = regionText
            self.specialtyText = specialtyText
            self.createdAt = createdAt
            self.approvedText = approvedText
            self.diagnosisCodeText = diagnosisCodeText
            self.encounterID = encounterID
            self.visible = visible
            self.allergy = allergy
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toStrictFollowUpAdjustmentView(_ item: StrictFollowUpAdjustment) -> StrictFollowUpAdjustmentView {
        return StrictFollowUpAdjustmentView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            regionText: item.region,
            specialtyText: item.specialty,
            createdAt: String(item.createdAt),
            approvedText: "\(item.approved)",
            diagnosisCodeText: item.diagnosisCode,
            encounterID: item.encounterID,
            visible: "\(item.visible)",
            allergy: item.allergy,
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictFollowUpAdjustmentViews(_ items: [StrictFollowUpAdjustment]) -> [StrictFollowUpAdjustmentView] {
        var views: [StrictFollowUpAdjustmentView] = []
        for item in items {
            views.append(toStrictFollowUpAdjustmentView(item))
        }
        return views
    }

    static func sumStrictFollowUpAdjustmentView(_ view: StrictFollowUpAdjustmentView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedCreatedAt)
    }
}
