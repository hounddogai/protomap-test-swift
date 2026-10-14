import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board template.
    final class BedBoardTemplateView {
        var code: String
        var title: String
        var createdAtText: String
        var active: String
        var clinicianIDText: String
        var floorValue: String
        var budgetText: String
        var ward: String
        var descriptionText: String
        var weight: String
        var statusLabel: String

        init(code: String, title: String, createdAtText: String, active: String, clinicianIDText: String, floorValue: String, budgetText: String, ward: String, descriptionText: String, weight: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.createdAtText = createdAtText
            self.active = active
            self.clinicianIDText = clinicianIDText
            self.floorValue = floorValue
            self.budgetText = budgetText
            self.ward = ward
            self.descriptionText = descriptionText
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardTemplateView(_ item: BedBoardTemplate) -> BedBoardTemplateView {
        return BedBoardTemplateView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            createdAtText: String(item.createdAt),
            active: "\(item.active)",
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            budgetText: String(format: "%.2f", item.budget),
            ward: item.ward,
            descriptionText: item.description,
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardTemplateViews(_ items: [BedBoardTemplate]) -> [BedBoardTemplateView] {
        var views: [BedBoardTemplateView] = []
        for item in items {
            views.append(toBedBoardTemplateView(item))
        }
        return views
    }

    static func sumBedBoardTemplateView(_ view: BedBoardTemplateView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedCreatedAt) + parsedFloorValue + parsedBudget
    }
}
