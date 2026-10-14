import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback outreach assignment.
    final class FallbackOutreachAssignmentView {
        var code: String
        var label: String
        var wardText: String
        var acuity: String
        var archivedText: String
        var segment: String
        var minimum: String
        var durationMinutes: String
        var quantity: String
        var statusLabel: String

        init(code: String, label: String, wardText: String, acuity: String, archivedText: String, segment: String, minimum: String, durationMinutes: String, quantity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.wardText = wardText
            self.acuity = acuity
            self.archivedText = archivedText
            self.segment = segment
            self.minimum = minimum
            self.durationMinutes = durationMinutes
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackOutreachAssignmentView(_ item: FallbackOutreachAssignment) -> FallbackOutreachAssignmentView {
        return FallbackOutreachAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            wardText: item.ward,
            acuity: String(item.acuity),
            archivedText: "\(item.archived)",
            segment: Kit.Text.truncate(item.segment, limit: 80),
            minimum: String(format: "%.2f", item.minimum),
            durationMinutes: String(item.durationMinutes),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackOutreachAssignmentViews(_ items: [FallbackOutreachAssignment]) -> [FallbackOutreachAssignmentView] {
        var views: [FallbackOutreachAssignmentView] = []
        for item in items {
            views.append(toFallbackOutreachAssignmentView(item))
        }
        return views
    }

    static func sumFallbackOutreachAssignmentView(_ view: FallbackOutreachAssignmentView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedAcuity) + parsedMinimum + Double(parsedDurationMinutes)
    }
}
