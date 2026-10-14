import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory request.
    final class InventoryRequestView {
        var code: String
        var title: String
        var acuityText: String
        var locale: String
        var budget: String
        var channelText: String
        var refills: String
        var statusLabel: String

        init(code: String, title: String, acuityText: String, locale: String, budget: String, channelText: String, refills: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.acuityText = acuityText
            self.locale = locale
            self.budget = budget
            self.channelText = channelText
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryRequestView(_ item: InventoryRequest) -> InventoryRequestView {
        return InventoryRequestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            acuityText: String(item.acuity),
            locale: Kit.Text.truncate(item.locale, limit: 64),
            budget: String(format: "%.2f", item.budget),
            channelText: item.channel,
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryRequestViews(_ items: [InventoryRequest]) -> [InventoryRequestView] {
        var views: [InventoryRequestView] = []
        for item in items {
            views.append(toInventoryRequestView(item))
        }
        return views
    }

    static func sumInventoryRequestView(_ view: InventoryRequestView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedAcuity) + parsedBudget + Double(parsedRefills)
    }
}
