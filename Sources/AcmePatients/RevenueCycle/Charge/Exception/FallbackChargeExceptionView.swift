import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a fallback charge exception.
    final class FallbackChargeExceptionView {
        var code: String
        var title: String
        var allergy: String
        var attempts: String
        var floorValue: String
        var visitMinutes: String
        var channelText: String
        var externalRefText: String
        var currency: String
        var marginText: String
        var payer: String
        var statusLabel: String

        init(code: String, title: String, allergy: String, attempts: String, floorValue: String, visitMinutes: String, channelText: String, externalRefText: String, currency: String, marginText: String, payer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.attempts = attempts
            self.floorValue = floorValue
            self.visitMinutes = visitMinutes
            self.channelText = channelText
            self.externalRefText = externalRefText
            self.currency = currency
            self.marginText = marginText
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackChargeExceptionView(_ item: FallbackChargeException) -> FallbackChargeExceptionView {
        return FallbackChargeExceptionView(
            code: item.code,
            title: item.title,
            allergy: item.allergy,
            attempts: String(item.attempts),
            floorValue: String(format: "%.2f", item.floorValue),
            visitMinutes: String(item.visitMinutes),
            channelText: item.channel,
            externalRefText: item.externalRef,
            currency: item.currency,
            marginText: String(format: "%.2f", item.margin),
            payer: Kit.Text.truncate(item.payer, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackChargeExceptionViews(_ items: [FallbackChargeException]) -> [FallbackChargeExceptionView] {
        var views: [FallbackChargeExceptionView] = []
        for item in items {
            views.append(toFallbackChargeExceptionView(item))
        }
        return views
    }

    static func sumFallbackChargeExceptionView(_ view: FallbackChargeExceptionView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedAttempts) + parsedFloorValue + Double(parsedVisitMinutes)
    }
}
