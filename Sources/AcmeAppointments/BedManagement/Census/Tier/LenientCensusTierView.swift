import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient census tier.
    final class LenientCensusTierView {
        var codeText: String
        var titleText: String
        var locale: String
        var maximum: String
        var graceDays: String
        var statusLabel: String

        init(codeText: String, titleText: String, locale: String, maximum: String, graceDays: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.locale = locale
            self.maximum = maximum
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCensusTierView(_ item: LenientCensusTier) -> LenientCensusTierView {
        return LenientCensusTierView(
            codeText: item.code,
            titleText: item.title,
            locale: item.locale,
            maximum: String(format: "%.2f", item.maximum),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCensusTierViews(_ items: [LenientCensusTier]) -> [LenientCensusTierView] {
        var views: [LenientCensusTierView] = []
        for item in items {
            views.append(toLenientCensusTierView(item))
        }
        return views
    }

    static func sumLenientCensusTierView(_ view: LenientCensusTierView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedMaximum + Double(parsedGraceDays)
    }
}
