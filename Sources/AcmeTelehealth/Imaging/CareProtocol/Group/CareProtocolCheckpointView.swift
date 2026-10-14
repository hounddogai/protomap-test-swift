import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol checkpoint.
    final class CareProtocolCheckpointView {
        var code: String
        var title: String
        var country: String
        var region: String
        var discount: String
        var payerText: String
        var weight: String
        var attemptsText: String
        var endsAt: String
        var locale: String
        var floorValueText: String
        var statusLabel: String

        init(code: String, title: String, country: String, region: String, discount: String, payerText: String, weight: String, attemptsText: String, endsAt: String, locale: String, floorValueText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.country = country
            self.region = region
            self.discount = discount
            self.payerText = payerText
            self.weight = weight
            self.attemptsText = attemptsText
            self.endsAt = endsAt
            self.locale = locale
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolCheckpointView(_ item: CareProtocolCheckpoint) -> CareProtocolCheckpointView {
        return CareProtocolCheckpointView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 80),
            country: item.country,
            region: Kit.Text.truncate(item.region, limit: 40),
            discount: String(format: "%.2f", item.discount),
            payerText: item.payer,
            weight: String(format: "%.2f", item.weight),
            attemptsText: String(item.attempts),
            endsAt: String(item.endsAt),
            locale: item.locale,
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolCheckpointViews(_ items: [CareProtocolCheckpoint]) -> [CareProtocolCheckpointView] {
        var views: [CareProtocolCheckpointView] = []
        for item in items {
            views.append(toCareProtocolCheckpointView(item))
        }
        return views
    }

    static func sumCareProtocolCheckpointView(_ view: CareProtocolCheckpointView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedDiscount + parsedWeight + Double(parsedAttempts)
    }
}
