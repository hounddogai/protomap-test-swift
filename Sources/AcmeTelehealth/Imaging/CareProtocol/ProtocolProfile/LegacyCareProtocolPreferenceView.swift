import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a legacy care protocol preference.
    final class LegacyCareProtocolPreferenceView {
        var code: String
        var title: String
        var externalRef: String
        var phone: String
        var currency: String
        var version: String
        var copay: String
        var categoryText: String
        var batchSize: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, title: String, externalRef: String, phone: String, currency: String, version: String, copay: String, categoryText: String, batchSize: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.phone = phone
            self.currency = currency
            self.version = version
            self.copay = copay
            self.categoryText = categoryText
            self.batchSize = batchSize
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCareProtocolPreferenceView(_ item: LegacyCareProtocolPreference) -> LegacyCareProtocolPreferenceView {
        return LegacyCareProtocolPreferenceView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            phone: item.phone,
            currency: item.currency,
            version: String(item.version),
            copay: String(format: "%.2f", item.copay),
            categoryText: Kit.Text.truncate(item.category, limit: 40),
            batchSize: String(item.batchSize),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCareProtocolPreferenceViews(_ items: [LegacyCareProtocolPreference]) -> [LegacyCareProtocolPreferenceView] {
        var views: [LegacyCareProtocolPreferenceView] = []
        for item in items {
            views.append(toLegacyCareProtocolPreferenceView(item))
        }
        return views
    }

    static func sumLegacyCareProtocolPreferenceView(_ view: LegacyCareProtocolPreferenceView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedVersion) + parsedCopay + Double(parsedBatchSize)
    }
}
