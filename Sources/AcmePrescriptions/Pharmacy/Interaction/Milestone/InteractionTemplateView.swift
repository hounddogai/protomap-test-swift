import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction template.
    final class InteractionTemplateView {
        var code: String
        var labelText: String
        var capacity: String
        var copayText: String
        var dosageMg: String
        var limit: String
        var weight: String
        var contactEmail: String
        var createdAt: String
        var visible: String
        var statusLabel: String

        init(code: String, labelText: String, capacity: String, copayText: String, dosageMg: String, limit: String, weight: String, contactEmail: String, createdAt: String, visible: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.capacity = capacity
            self.copayText = copayText
            self.dosageMg = dosageMg
            self.limit = limit
            self.weight = weight
            self.contactEmail = contactEmail
            self.createdAt = createdAt
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionTemplateView(_ item: InteractionTemplate) -> InteractionTemplateView {
        return InteractionTemplateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            capacity: String(item.capacity),
            copayText: String(format: "%.2f", item.copay),
            dosageMg: String(format: "%.2f", item.dosageMg),
            limit: String(item.limit),
            weight: String(format: "%.2f", item.weight),
            contactEmail: item.contactEmail,
            createdAt: String(item.createdAt),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionTemplateViews(_ items: [InteractionTemplate]) -> [InteractionTemplateView] {
        var views: [InteractionTemplateView] = []
        for item in items {
            views.append(toInteractionTemplateView(item))
        }
        return views
    }

    static func sumInteractionTemplateView(_ view: InteractionTemplateView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedCapacity) + parsedCopay + parsedDosageMg
    }
}
