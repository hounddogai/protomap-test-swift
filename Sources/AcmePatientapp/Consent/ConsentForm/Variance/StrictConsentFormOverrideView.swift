import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a strict consent form override.
    final class StrictConsentFormOverrideView {
        var code: String
        var name: String
        var descriptionText: String
        var payer: String
        var createdAt: String
        var ceiling: String
        var margin: String
        var bedText: String
        var checksum: String
        var amount: String
        var floorValueText: String
        var statusLabel: String

        init(code: String, name: String, descriptionText: String, payer: String, createdAt: String, ceiling: String, margin: String, bedText: String, checksum: String, amount: String, floorValueText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.descriptionText = descriptionText
            self.payer = payer
            self.createdAt = createdAt
            self.ceiling = ceiling
            self.margin = margin
            self.bedText = bedText
            self.checksum = checksum
            self.amount = amount
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictConsentFormOverrideView(_ item: StrictConsentFormOverride) -> StrictConsentFormOverrideView {
        return StrictConsentFormOverrideView(
            code: item.code,
            name: item.name,
            descriptionText: item.description,
            payer: item.payer,
            createdAt: String(item.createdAt),
            ceiling: String(format: "%.2f", item.ceiling),
            margin: String(format: "%.2f", item.margin),
            bedText: item.bed,
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            amount: String(format: "%.2f", item.amount),
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictConsentFormOverrideViews(_ items: [StrictConsentFormOverride]) -> [StrictConsentFormOverrideView] {
        var views: [StrictConsentFormOverrideView] = []
        for item in items {
            views.append(toStrictConsentFormOverrideView(item))
        }
        return views
    }

    static func sumStrictConsentFormOverrideView(_ view: StrictConsentFormOverrideView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedCreatedAt) + parsedCeiling + parsedMargin
    }
}
