import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a manual care protocol bundle.
    final class ManualCareProtocolBundleView {
        var code: String
        var title: String
        var country: String
        var facilityText: String
        var segment: String
        var quantityText: String
        var statusLabel: String

        init(code: String, title: String, country: String, facilityText: String, segment: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.country = country
            self.facilityText = facilityText
            self.segment = segment
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toManualCareProtocolBundleView(_ item: ManualCareProtocolBundle) -> ManualCareProtocolBundleView {
        return ManualCareProtocolBundleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            country: item.country,
            facilityText: Kit.Text.truncate(item.facility, limit: 40),
            segment: item.segment,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCareProtocolBundleViews(_ items: [ManualCareProtocolBundle]) -> [ManualCareProtocolBundleView] {
        var views: [ManualCareProtocolBundleView] = []
        for item in items {
            views.append(toManualCareProtocolBundleView(item))
        }
        return views
    }

    static func sumManualCareProtocolBundleView(_ view: ManualCareProtocolBundleView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
