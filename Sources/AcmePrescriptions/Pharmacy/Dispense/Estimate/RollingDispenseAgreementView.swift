import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling dispense agreement.
    final class RollingDispenseAgreementView {
        var code: String
        var title: String
        var procedureCode: String
        var windowDays: String
        var endsAt: String
        var encounterID: String
        var quantity: String
        var floorValueText: String
        var limitText: String
        var priority: String
        var discount: String
        var statusLabel: String

        init(code: String, title: String, procedureCode: String, windowDays: String, endsAt: String, encounterID: String, quantity: String, floorValueText: String, limitText: String, priority: String, discount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.windowDays = windowDays
            self.endsAt = endsAt
            self.encounterID = encounterID
            self.quantity = quantity
            self.floorValueText = floorValueText
            self.limitText = limitText
            self.priority = priority
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toRollingDispenseAgreementView(_ item: RollingDispenseAgreement) -> RollingDispenseAgreementView {
        return RollingDispenseAgreementView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            procedureCode: item.procedureCode,
            windowDays: String(item.windowDays),
            endsAt: String(item.endsAt),
            encounterID: item.encounterID,
            quantity: String(item.quantity),
            floorValueText: String(format: "%.2f", item.floorValue),
            limitText: String(item.limit),
            priority: String(item.priority),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingDispenseAgreementViews(_ items: [RollingDispenseAgreement]) -> [RollingDispenseAgreementView] {
        var views: [RollingDispenseAgreementView] = []
        for item in items {
            views.append(toRollingDispenseAgreementView(item))
        }
        return views
    }

    static func sumRollingDispenseAgreementView(_ view: RollingDispenseAgreementView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedEndsAt) + Double(parsedQuantity)
    }
}
