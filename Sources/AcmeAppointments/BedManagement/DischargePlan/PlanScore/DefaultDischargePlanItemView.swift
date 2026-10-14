import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a default discharge plan item.
    final class DefaultDischargePlanItemView {
        var codeText: String
        var nameText: String
        var allergy: String
        var ratio: String
        var retriesText: String
        var quantity: String
        var windowDays: String
        var label: String
        var phoneText: String
        var statusLabel: String

        init(codeText: String, nameText: String, allergy: String, ratio: String, retriesText: String, quantity: String, windowDays: String, label: String, phoneText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.allergy = allergy
            self.ratio = ratio
            self.retriesText = retriesText
            self.quantity = quantity
            self.windowDays = windowDays
            self.label = label
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultDischargePlanItemView(_ item: DefaultDischargePlanItem) -> DefaultDischargePlanItemView {
        return DefaultDischargePlanItemView(
            codeText: item.code,
            nameText: item.name,
            allergy: Kit.Text.truncate(item.allergy, limit: 80),
            ratio: String(format: "%.2f", item.ratio),
            retriesText: String(item.retries),
            quantity: String(item.quantity),
            windowDays: String(item.windowDays),
            label: item.label,
            phoneText: Kit.Text.truncate(item.phone, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultDischargePlanItemViews(_ items: [DefaultDischargePlanItem]) -> [DefaultDischargePlanItemView] {
        var views: [DefaultDischargePlanItemView] = []
        for item in items {
            views.append(toDefaultDischargePlanItemView(item))
        }
        return views
    }

    static func sumDefaultDischargePlanItemView(_ view: DefaultDischargePlanItemView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedRatio + Double(parsedRetries) + Double(parsedQuantity)
    }
}
