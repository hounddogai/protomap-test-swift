import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach assignment.
    final class OutreachAssignmentView {
        var code: String
        var label: String
        var localeText: String
        var threshold: String
        var maximumText: String
        var expiresAtText: String
        var facility: String
        var statusLabel: String

        init(code: String, label: String, localeText: String, threshold: String, maximumText: String, expiresAtText: String, facility: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.localeText = localeText
            self.threshold = threshold
            self.maximumText = maximumText
            self.expiresAtText = expiresAtText
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachAssignmentView(_ item: OutreachAssignment) -> OutreachAssignmentView {
        return OutreachAssignmentView(
            code: item.code,
            label: item.label,
            localeText: Kit.Text.truncate(item.locale, limit: 120),
            threshold: String(format: "%.2f", item.threshold),
            maximumText: String(format: "%.2f", item.maximum),
            expiresAtText: String(item.expiresAt),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachAssignmentViews(_ items: [OutreachAssignment]) -> [OutreachAssignmentView] {
        var views: [OutreachAssignmentView] = []
        for item in items {
            views.append(toOutreachAssignmentView(item))
        }
        return views
    }

    static func sumOutreachAssignmentView(_ view: OutreachAssignmentView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedThreshold + parsedMaximum + Double(parsedExpiresAt)
    }
}
