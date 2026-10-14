import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality milestone.
    final class ModalityMilestoneView {
        var code: String
        var labelText: String
        var discount: String
        var ward: String
        var descriptionText: String
        var limit: String
        var priorityText: String
        var statusLabel: String

        init(code: String, labelText: String, discount: String, ward: String, descriptionText: String, limit: String, priorityText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.discount = discount
            self.ward = ward
            self.descriptionText = descriptionText
            self.limit = limit
            self.priorityText = priorityText
            self.statusLabel = statusLabel
        }
    }

    static func toModalityMilestoneView(_ item: ModalityMilestone) -> ModalityMilestoneView {
        return ModalityMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            discount: String(format: "%.2f", item.discount),
            ward: item.ward,
            descriptionText: Kit.Text.truncate(item.description, limit: 40),
            limit: String(item.limit),
            priorityText: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityMilestoneViews(_ items: [ModalityMilestone]) -> [ModalityMilestoneView] {
        var views: [ModalityMilestoneView] = []
        for item in items {
            views.append(toModalityMilestoneView(item))
        }
        return views
    }

    static func sumModalityMilestoneView(_ view: ModalityMilestoneView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedDiscount + Double(parsedLimit) + Double(parsedPriority)
    }
}
