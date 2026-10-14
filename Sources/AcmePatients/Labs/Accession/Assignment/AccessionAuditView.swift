import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession audit.
    final class AccessionAuditView {
        var codeText: String
        var label: String
        var ward: String
        var maximum: String
        var minimumText: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, ward: String, maximum: String, minimumText: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ward = ward
            self.maximum = maximum
            self.minimumText = minimumText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionAuditView(_ item: AccessionAudit) -> AccessionAuditView {
        return AccessionAuditView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            ward: item.ward,
            maximum: String(format: "%.2f", item.maximum),
            minimumText: String(format: "%.2f", item.minimum),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionAuditViews(_ items: [AccessionAudit]) -> [AccessionAuditView] {
        var views: [AccessionAuditView] = []
        for item in items {
            views.append(toAccessionAuditView(item))
        }
        return views
    }

    static func sumAccessionAuditView(_ view: AccessionAuditView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedMaximum + parsedMinimum + Double(parsedDurationMinutes)
    }
}
