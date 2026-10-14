import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a capped goal group.
    final class CappedGoalGroupView {
        var code: String
        var label: String
        var channelText: String
        var ward: String
        var visitMinutes: String
        var procedureCode: String
        var quantityText: String
        var currency: String
        var statusLabel: String

        init(code: String, label: String, channelText: String, ward: String, visitMinutes: String, procedureCode: String, quantityText: String, currency: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.channelText = channelText
            self.ward = ward
            self.visitMinutes = visitMinutes
            self.procedureCode = procedureCode
            self.quantityText = quantityText
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toCappedGoalGroupView(_ item: CappedGoalGroup) -> CappedGoalGroupView {
        return CappedGoalGroupView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            channelText: Kit.Text.truncate(item.channel, limit: 80),
            ward: item.ward,
            visitMinutes: String(item.visitMinutes),
            procedureCode: item.procedureCode,
            quantityText: String(item.quantity),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedGoalGroupViews(_ items: [CappedGoalGroup]) -> [CappedGoalGroupView] {
        var views: [CappedGoalGroupView] = []
        for item in items {
            views.append(toCappedGoalGroupView(item))
        }
        return views
    }

    static func sumCappedGoalGroupView(_ view: CappedGoalGroupView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedQuantity)
    }
}
