import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a tiered acuity plan milestone.
    final class TieredAcuityPlanMilestoneView {
        var codeText: String
        var nameText: String
        var createdAt: String
        var margin: String
        var ward: String
        var procedureCode: String
        var notesText: String
        var statusLabel: String

        init(codeText: String, nameText: String, createdAt: String, margin: String, ward: String, procedureCode: String, notesText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.createdAt = createdAt
            self.margin = margin
            self.ward = ward
            self.procedureCode = procedureCode
            self.notesText = notesText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredAcuityPlanMilestoneView(_ item: TieredAcuityPlanMilestone) -> TieredAcuityPlanMilestoneView {
        return TieredAcuityPlanMilestoneView(
            codeText: item.code,
            nameText: item.name,
            createdAt: String(item.createdAt),
            margin: String(format: "%.2f", item.margin),
            ward: item.ward,
            procedureCode: item.procedureCode,
            notesText: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredAcuityPlanMilestoneViews(_ items: [TieredAcuityPlanMilestone]) -> [TieredAcuityPlanMilestoneView] {
        var views: [TieredAcuityPlanMilestoneView] = []
        for item in items {
            views.append(toTieredAcuityPlanMilestoneView(item))
        }
        return views
    }

    static func sumTieredAcuityPlanMilestoneView(_ view: TieredAcuityPlanMilestoneView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedCreatedAt) + parsedMargin
    }
}
