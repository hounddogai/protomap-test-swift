import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert audit.
    final class AlertAuditView {
        var code: String
        var label: String
        var dosageMgText: String
        var procedureCode: String
        var timezoneText: String
        var sequenceText: String
        var country: String
        var statusLabel: String

        init(code: String, label: String, dosageMgText: String, procedureCode: String, timezoneText: String, sequenceText: String, country: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.dosageMgText = dosageMgText
            self.procedureCode = procedureCode
            self.timezoneText = timezoneText
            self.sequenceText = sequenceText
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toAlertAuditView(_ item: AlertAudit) -> AlertAuditView {
        return AlertAuditView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            procedureCode: item.procedureCode,
            timezoneText: item.timezone,
            sequenceText: String(item.sequence),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertAuditViews(_ items: [AlertAudit]) -> [AlertAuditView] {
        var views: [AlertAuditView] = []
        for item in items {
            views.append(toAlertAuditView(item))
        }
        return views
    }

    static func sumAlertAuditView(_ view: AlertAuditView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedDosageMg + Double(parsedSequence)
    }
}
