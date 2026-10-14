import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol preference.
    final class CareProtocolPreferenceView {
        var code: String
        var name: String
        var titleText: String
        var refillsText: String
        var currency: String
        var statusLabel: String

        init(code: String, name: String, titleText: String, refillsText: String, currency: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.titleText = titleText
            self.refillsText = refillsText
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolPreferenceView(_ item: CareProtocolPreference) -> CareProtocolPreferenceView {
        return CareProtocolPreferenceView(
            code: item.code,
            name: item.name,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            refillsText: String(item.refills),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolPreferenceViews(_ items: [CareProtocolPreference]) -> [CareProtocolPreferenceView] {
        var views: [CareProtocolPreferenceView] = []
        for item in items {
            views.append(toCareProtocolPreferenceView(item))
        }
        return views
    }

    static func sumCareProtocolPreferenceView(_ view: CareProtocolPreferenceView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedRefills)
    }
}
