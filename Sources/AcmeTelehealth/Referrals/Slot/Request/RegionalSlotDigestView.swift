import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional slot digest.
    final class RegionalSlotDigestView {
        var code: String
        var label: String
        var createdAtText: String
        var externalRef: String
        var phone: String
        var batchSize: String
        var statusLabel: String

        init(code: String, label: String, createdAtText: String, externalRef: String, phone: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAtText = createdAtText
            self.externalRef = externalRef
            self.phone = phone
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalSlotDigestView(_ item: RegionalSlotDigest) -> RegionalSlotDigestView {
        return RegionalSlotDigestView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            createdAtText: String(item.createdAt),
            externalRef: item.externalRef,
            phone: item.phone,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalSlotDigestViews(_ items: [RegionalSlotDigest]) -> [RegionalSlotDigestView] {
        var views: [RegionalSlotDigestView] = []
        for item in items {
            views.append(toRegionalSlotDigestView(item))
        }
        return views
    }

    static func sumRegionalSlotDigestView(_ view: RegionalSlotDigestView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedBatchSize)
    }
}
