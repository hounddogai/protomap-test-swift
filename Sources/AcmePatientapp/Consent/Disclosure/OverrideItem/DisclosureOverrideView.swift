import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure override.
    final class DisclosureOverrideView {
        var code: String
        var labelText: String
        var currency: String
        var batchSizeText: String
        var capacityText: String
        var checksum: String
        var nameText: String
        var encounterID: String
        var externalRef: String
        var expiresAt: String
        var retries: String
        var statusLabel: String

        init(code: String, labelText: String, currency: String, batchSizeText: String, capacityText: String, checksum: String, nameText: String, encounterID: String, externalRef: String, expiresAt: String, retries: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.currency = currency
            self.batchSizeText = batchSizeText
            self.capacityText = capacityText
            self.checksum = checksum
            self.nameText = nameText
            self.encounterID = encounterID
            self.externalRef = externalRef
            self.expiresAt = expiresAt
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureOverrideView(_ item: DisclosureOverride) -> DisclosureOverrideView {
        return DisclosureOverrideView(
            code: item.code,
            labelText: item.label,
            currency: item.currency,
            batchSizeText: String(item.batchSize),
            capacityText: String(item.capacity),
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            nameText: item.name,
            encounterID: item.encounterID,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            expiresAt: String(item.expiresAt),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureOverrideViews(_ items: [DisclosureOverride]) -> [DisclosureOverrideView] {
        var views: [DisclosureOverrideView] = []
        for item in items {
            views.append(toDisclosureOverrideView(item))
        }
        return views
    }

    static func sumDisclosureOverrideView(_ view: DisclosureOverrideView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedCapacity) + Double(parsedExpiresAt)
    }
}
