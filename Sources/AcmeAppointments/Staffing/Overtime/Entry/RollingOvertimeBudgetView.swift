import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a rolling overtime budget.
    final class RollingOvertimeBudgetView {
        var code: String
        var title: String
        var procedureCode: String
        var descriptionText: String
        var country: String
        var diagnosisCodeText: String
        var quantity: String
        var segment: String
        var archived: String
        var statusLabel: String

        init(code: String, title: String, procedureCode: String, descriptionText: String, country: String, diagnosisCodeText: String, quantity: String, segment: String, archived: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.descriptionText = descriptionText
            self.country = country
            self.diagnosisCodeText = diagnosisCodeText
            self.quantity = quantity
            self.segment = segment
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toRollingOvertimeBudgetView(_ item: RollingOvertimeBudget) -> RollingOvertimeBudgetView {
        return RollingOvertimeBudgetView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            descriptionText: item.description,
            country: item.country,
            diagnosisCodeText: item.diagnosisCode,
            quantity: String(item.quantity),
            segment: Kit.Text.truncate(item.segment, limit: 64),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingOvertimeBudgetViews(_ items: [RollingOvertimeBudget]) -> [RollingOvertimeBudgetView] {
        var views: [RollingOvertimeBudgetView] = []
        for item in items {
            views.append(toRollingOvertimeBudgetView(item))
        }
        return views
    }

    static func sumRollingOvertimeBudgetView(_ view: RollingOvertimeBudgetView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
