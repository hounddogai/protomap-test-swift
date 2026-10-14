import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual charge mapping.
    final class ManualChargeMappingView {
        var code: String
        var title: String
        var segment: String
        var sequence: String
        var marginText: String
        var currency: String
        var visibleText: String
        var payer: String
        var timezoneText: String
        var facility: String
        var countryText: String
        var statusLabel: String

        init(code: String, title: String, segment: String, sequence: String, marginText: String, currency: String, visibleText: String, payer: String, timezoneText: String, facility: String, countryText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.segment = segment
            self.sequence = sequence
            self.marginText = marginText
            self.currency = currency
            self.visibleText = visibleText
            self.payer = payer
            self.timezoneText = timezoneText
            self.facility = facility
            self.countryText = countryText
            self.statusLabel = statusLabel
        }
    }

    static func toManualChargeMappingView(_ item: ManualChargeMapping) -> ManualChargeMappingView {
        return ManualChargeMappingView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            segment: Kit.Text.truncate(item.segment, limit: 64),
            sequence: String(item.sequence),
            marginText: String(format: "%.2f", item.margin),
            currency: Kit.Text.truncate(item.currency, limit: 120),
            visibleText: "\(item.visible)",
            payer: item.payer,
            timezoneText: item.timezone,
            facility: item.facility,
            countryText: Kit.Text.truncate(item.country, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualChargeMappingViews(_ items: [ManualChargeMapping]) -> [ManualChargeMappingView] {
        var views: [ManualChargeMappingView] = []
        for item in items {
            views.append(toManualChargeMappingView(item))
        }
        return views
    }

    static func sumManualChargeMappingView(_ view: ManualChargeMappingView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedSequence) + parsedMargin
    }
}
