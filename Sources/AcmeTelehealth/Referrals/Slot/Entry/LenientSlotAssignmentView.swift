import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a lenient slot assignment.
    final class LenientSlotAssignmentView {
        var code: String
        var name: String
        var attemptsText: String
        var specialty: String
        var visible: String
        var contactEmail: String
        var labelText: String
        var statusLabel: String

        init(code: String, name: String, attemptsText: String, specialty: String, visible: String, contactEmail: String, labelText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.attemptsText = attemptsText
            self.specialty = specialty
            self.visible = visible
            self.contactEmail = contactEmail
            self.labelText = labelText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientSlotAssignmentView(_ item: LenientSlotAssignment) -> LenientSlotAssignmentView {
        return LenientSlotAssignmentView(
            code: item.code,
            name: item.name,
            attemptsText: String(item.attempts),
            specialty: item.specialty,
            visible: "\(item.visible)",
            contactEmail: item.contactEmail,
            labelText: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientSlotAssignmentViews(_ items: [LenientSlotAssignment]) -> [LenientSlotAssignmentView] {
        var views: [LenientSlotAssignmentView] = []
        for item in items {
            views.append(toLenientSlotAssignmentView(item))
        }
        return views
    }

    static func sumLenientSlotAssignmentView(_ view: LenientSlotAssignmentView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAttempts)
    }
}
