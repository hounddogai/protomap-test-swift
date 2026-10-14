import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan audit.
    final class AcuityPlanAuditView {
        var codeText: String
        var title: String
        var weight: String
        var notesText: String
        var label: String
        var windowDays: String
        var maximumText: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, title: String, weight: String, notesText: String, label: String, windowDays: String, maximumText: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.weight = weight
            self.notesText = notesText
            self.label = label
            self.windowDays = windowDays
            self.maximumText = maximumText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanAuditView(_ item: AcuityPlanAudit) -> AcuityPlanAuditView {
        return AcuityPlanAuditView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            weight: String(format: "%.2f", item.weight),
            notesText: item.notes,
            label: item.label,
            windowDays: String(item.windowDays),
            maximumText: String(format: "%.2f", item.maximum),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanAuditViews(_ items: [AcuityPlanAudit]) -> [AcuityPlanAuditView] {
        var views: [AcuityPlanAuditView] = []
        for item in items {
            views.append(toAcuityPlanAuditView(item))
        }
        return views
    }

    static func sumAcuityPlanAuditView(_ view: AcuityPlanAuditView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedWeight + Double(parsedWindowDays) + parsedMaximum
    }
}
