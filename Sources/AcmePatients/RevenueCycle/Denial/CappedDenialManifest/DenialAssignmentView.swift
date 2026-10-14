import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial assignment.
    final class DenialAssignmentView {
        var codeText: String
        var label: String
        var phone: String
        var contactEmail: String
        var ratioText: String
        var nameText: String
        var statusLabel: String

        init(codeText: String, label: String, phone: String, contactEmail: String, ratioText: String, nameText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.phone = phone
            self.contactEmail = contactEmail
            self.ratioText = ratioText
            self.nameText = nameText
            self.statusLabel = statusLabel
        }
    }

    static func toDenialAssignmentView(_ item: DenialAssignment) -> DenialAssignmentView {
        return DenialAssignmentView(
            codeText: item.code,
            label: item.label,
            phone: item.phone,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            ratioText: String(format: "%.2f", item.ratio),
            nameText: item.name,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialAssignmentViews(_ items: [DenialAssignment]) -> [DenialAssignmentView] {
        var views: [DenialAssignmentView] = []
        for item in items {
            views.append(toDenialAssignmentView(item))
        }
        return views
    }

    static func sumDenialAssignmentView(_ view: DenialAssignmentView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
