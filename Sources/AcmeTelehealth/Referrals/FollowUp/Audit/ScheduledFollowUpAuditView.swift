import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a scheduled follow up audit.
    final class ScheduledFollowUpAuditView {
        var code: String
        var title: String
        var diagnosisCode: String
        var encounterID: String
        var specialtyText: String
        var floorValue: String
        var externalRef: String
        var currency: String
        var statusLabel: String

        init(code: String, title: String, diagnosisCode: String, encounterID: String, specialtyText: String, floorValue: String, externalRef: String, currency: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.encounterID = encounterID
            self.specialtyText = specialtyText
            self.floorValue = floorValue
            self.externalRef = externalRef
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledFollowUpAuditView(_ item: ScheduledFollowUpAudit) -> ScheduledFollowUpAuditView {
        return ScheduledFollowUpAuditView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            specialtyText: item.specialty,
            floorValue: String(format: "%.2f", item.floorValue),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            currency: Kit.Text.truncate(item.currency, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledFollowUpAuditViews(_ items: [ScheduledFollowUpAudit]) -> [ScheduledFollowUpAuditView] {
        var views: [ScheduledFollowUpAuditView] = []
        for item in items {
            views.append(toScheduledFollowUpAuditView(item))
        }
        return views
    }

    static func sumScheduledFollowUpAuditView(_ view: ScheduledFollowUpAuditView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
