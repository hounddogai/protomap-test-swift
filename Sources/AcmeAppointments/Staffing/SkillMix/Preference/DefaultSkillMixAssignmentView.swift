import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a default skill mix assignment.
    final class DefaultSkillMixAssignmentView {
        var codeText: String
        var name: String
        var phone: String
        var updatedAtText: String
        var maximumText: String
        var costText: String
        var ward: String
        var batchSize: String
        var windowDaysText: String
        var statusLabel: String

        init(codeText: String, name: String, phone: String, updatedAtText: String, maximumText: String, costText: String, ward: String, batchSize: String, windowDaysText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.phone = phone
            self.updatedAtText = updatedAtText
            self.maximumText = maximumText
            self.costText = costText
            self.ward = ward
            self.batchSize = batchSize
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultSkillMixAssignmentView(_ item: DefaultSkillMixAssignment) -> DefaultSkillMixAssignmentView {
        return DefaultSkillMixAssignmentView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            phone: item.phone,
            updatedAtText: String(item.updatedAt),
            maximumText: String(format: "%.2f", item.maximum),
            costText: String(format: "%.2f", item.cost),
            ward: item.ward,
            batchSize: String(item.batchSize),
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultSkillMixAssignmentViews(_ items: [DefaultSkillMixAssignment]) -> [DefaultSkillMixAssignmentView] {
        var views: [DefaultSkillMixAssignmentView] = []
        for item in items {
            views.append(toDefaultSkillMixAssignmentView(item))
        }
        return views
    }

    static func sumDefaultSkillMixAssignmentView(_ view: DefaultSkillMixAssignmentView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedUpdatedAt) + parsedMaximum + parsedCost
    }
}
