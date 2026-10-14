import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert milestone.
    final class AlertMilestoneView {
        var codeText: String
        var title: String
        var quantity: String
        var timezoneText: String
        var patientRef: String
        var statusLabel: String

        init(codeText: String, title: String, quantity: String, timezoneText: String, patientRef: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.quantity = quantity
            self.timezoneText = timezoneText
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toAlertMilestoneView(_ item: AlertMilestone) -> AlertMilestoneView {
        return AlertMilestoneView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            quantity: String(item.quantity),
            timezoneText: item.timezone,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertMilestoneViews(_ items: [AlertMilestone]) -> [AlertMilestoneView] {
        var views: [AlertMilestoneView] = []
        for item in items {
            views.append(toAlertMilestoneView(item))
        }
        return views
    }

    static func sumAlertMilestoneView(_ view: AlertMilestoneView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
