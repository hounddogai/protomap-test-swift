import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set milestone.
    final class OrderSetMilestoneView {
        var code: String
        var label: String
        var limit: String
        var allergy: String
        var updatedAt: String
        var clinicianID: String
        var contactEmail: String
        var specialtyText: String
        var minimum: String
        var statusLabel: String

        init(code: String, label: String, limit: String, allergy: String, updatedAt: String, clinicianID: String, contactEmail: String, specialtyText: String, minimum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.limit = limit
            self.allergy = allergy
            self.updatedAt = updatedAt
            self.clinicianID = clinicianID
            self.contactEmail = contactEmail
            self.specialtyText = specialtyText
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetMilestoneView(_ item: OrderSetMilestone) -> OrderSetMilestoneView {
        return OrderSetMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            limit: String(item.limit),
            allergy: item.allergy,
            updatedAt: String(item.updatedAt),
            clinicianID: item.clinicianID,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            specialtyText: item.specialty,
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetMilestoneViews(_ items: [OrderSetMilestone]) -> [OrderSetMilestoneView] {
        var views: [OrderSetMilestoneView] = []
        for item in items {
            views.append(toOrderSetMilestoneView(item))
        }
        return views
    }

    static func sumOrderSetMilestoneView(_ view: OrderSetMilestoneView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedLimit) + Double(parsedUpdatedAt) + parsedMinimum
    }
}
