import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot audit.
    final class SlotAuditView {
        var code: String
        var label: String
        var threshold: String
        var timezone: String
        var title: String
        var approved: String
        var diagnosisCode: String
        var acuity: String
        var quantityText: String
        var visibleText: String
        var procedureCodeText: String
        var statusLabel: String

        init(code: String, label: String, threshold: String, timezone: String, title: String, approved: String, diagnosisCode: String, acuity: String, quantityText: String, visibleText: String, procedureCodeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.timezone = timezone
            self.title = title
            self.approved = approved
            self.diagnosisCode = diagnosisCode
            self.acuity = acuity
            self.quantityText = quantityText
            self.visibleText = visibleText
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotAuditView(_ item: SlotAudit) -> SlotAuditView {
        return SlotAuditView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            threshold: String(format: "%.2f", item.threshold),
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 40),
            approved: "\(item.approved)",
            diagnosisCode: item.diagnosisCode,
            acuity: String(item.acuity),
            quantityText: String(item.quantity),
            visibleText: "\(item.visible)",
            procedureCodeText: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotAuditViews(_ items: [SlotAudit]) -> [SlotAuditView] {
        var views: [SlotAuditView] = []
        for item in items {
            views.append(toSlotAuditView(item))
        }
        return views
    }

    static func sumSlotAuditView(_ view: SlotAuditView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedThreshold + Double(parsedAcuity) + Double(parsedQuantity)
    }
}
