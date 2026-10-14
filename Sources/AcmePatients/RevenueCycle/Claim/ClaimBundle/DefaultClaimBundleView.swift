import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a default claim bundle.
    final class DefaultClaimBundleView {
        var code: String
        var titleText: String
        var quantity: String
        var floorValueText: String
        var pinnedText: String
        var currency: String
        var statusLabel: String

        init(code: String, titleText: String, quantity: String, floorValueText: String, pinnedText: String, currency: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.quantity = quantity
            self.floorValueText = floorValueText
            self.pinnedText = pinnedText
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultClaimBundleView(_ item: DefaultClaimBundle) -> DefaultClaimBundleView {
        return DefaultClaimBundleView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            quantity: String(item.quantity),
            floorValueText: String(format: "%.2f", item.floorValue),
            pinnedText: "\(item.pinned)",
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultClaimBundleViews(_ items: [DefaultClaimBundle]) -> [DefaultClaimBundleView] {
        var views: [DefaultClaimBundleView] = []
        for item in items {
            views.append(toDefaultClaimBundleView(item))
        }
        return views
    }

    static func sumDefaultClaimBundleView(_ view: DefaultClaimBundleView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedQuantity) + parsedFloorValue
    }
}
