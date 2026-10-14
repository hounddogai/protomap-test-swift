import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol summary.
    final class CareProtocolSummaryView {
        var code: String
        var label: String
        var discount: String
        var startsAtText: String
        var phone: String
        var statusLabel: String

        init(code: String, label: String, discount: String, startsAtText: String, phone: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discount = discount
            self.startsAtText = startsAtText
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolSummaryView(_ item: CareProtocolSummary) -> CareProtocolSummaryView {
        return CareProtocolSummaryView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 64),
            discount: String(format: "%.2f", item.discount),
            startsAtText: String(item.startsAt),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolSummaryViews(_ items: [CareProtocolSummary]) -> [CareProtocolSummaryView] {
        var views: [CareProtocolSummaryView] = []
        for item in items {
            views.append(toCareProtocolSummaryView(item))
        }
        return views
    }

    static func sumCareProtocolSummaryView(_ view: CareProtocolSummaryView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedDiscount + Double(parsedStartsAt)
    }
}
