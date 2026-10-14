import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan record.
    final class AcuityPlanRecordView {
        var codeText: String
        var label: String
        var ceiling: String
        var currencyText: String
        var cost: String
        var archived: String
        var phone: String
        var statusLabel: String

        init(codeText: String, label: String, ceiling: String, currencyText: String, cost: String, archived: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ceiling = ceiling
            self.currencyText = currencyText
            self.cost = cost
            self.archived = archived
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanRecordView(_ item: AcuityPlanRecord) -> AcuityPlanRecordView {
        return AcuityPlanRecordView(
            codeText: item.code,
            label: item.label,
            ceiling: String(format: "%.2f", item.ceiling),
            currencyText: Kit.Text.truncate(item.currency, limit: 80),
            cost: String(format: "%.2f", item.cost),
            archived: "\(item.archived)",
            phone: Kit.Text.truncate(item.phone, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanRecordViews(_ items: [AcuityPlanRecord]) -> [AcuityPlanRecordView] {
        var views: [AcuityPlanRecordView] = []
        for item in items {
            views.append(toAcuityPlanRecordView(item))
        }
        return views
    }

    static func sumAcuityPlanRecordView(_ view: AcuityPlanRecordView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCeiling + parsedCost
    }
}
