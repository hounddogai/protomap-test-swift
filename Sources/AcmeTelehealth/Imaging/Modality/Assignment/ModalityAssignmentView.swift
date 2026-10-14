import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality assignment.
    final class ModalityAssignmentView {
        var code: String
        var name: String
        var ratioText: String
        var expiresAt: String
        var cost: String
        var versionText: String
        var notes: String
        var quantity: String
        var acuity: String
        var description: String
        var statusLabel: String

        init(code: String, name: String, ratioText: String, expiresAt: String, cost: String, versionText: String, notes: String, quantity: String, acuity: String, description: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ratioText = ratioText
            self.expiresAt = expiresAt
            self.cost = cost
            self.versionText = versionText
            self.notes = notes
            self.quantity = quantity
            self.acuity = acuity
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toModalityAssignmentView(_ item: ModalityAssignment) -> ModalityAssignmentView {
        return ModalityAssignmentView(
            code: item.code,
            name: item.name,
            ratioText: String(format: "%.2f", item.ratio),
            expiresAt: String(item.expiresAt),
            cost: String(format: "%.2f", item.cost),
            versionText: String(item.version),
            notes: item.notes,
            quantity: String(item.quantity),
            acuity: String(item.acuity),
            description: Kit.Text.truncate(item.description, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityAssignmentViews(_ items: [ModalityAssignment]) -> [ModalityAssignmentView] {
        var views: [ModalityAssignmentView] = []
        for item in items {
            views.append(toModalityAssignmentView(item))
        }
        return views
    }

    static func sumModalityAssignmentView(_ view: ModalityAssignmentView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedRatio + Double(parsedExpiresAt) + parsedCost
    }
}
