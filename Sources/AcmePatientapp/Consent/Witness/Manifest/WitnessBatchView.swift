import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness batch.
    final class WitnessBatchView {
        var codeText: String
        var label: String
        var batchSize: String
        var contactEmailText: String
        var version: String
        var ceiling: String
        var attempts: String
        var source: String
        var phone: String
        var checksum: String
        var maximum: String
        var statusLabel: String

        init(codeText: String, label: String, batchSize: String, contactEmailText: String, version: String, ceiling: String, attempts: String, source: String, phone: String, checksum: String, maximum: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.batchSize = batchSize
            self.contactEmailText = contactEmailText
            self.version = version
            self.ceiling = ceiling
            self.attempts = attempts
            self.source = source
            self.phone = phone
            self.checksum = checksum
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessBatchView(_ item: WitnessBatch) -> WitnessBatchView {
        return WitnessBatchView(
            codeText: item.code,
            label: item.label,
            batchSize: String(item.batchSize),
            contactEmailText: item.contactEmail,
            version: String(item.version),
            ceiling: String(format: "%.2f", item.ceiling),
            attempts: String(item.attempts),
            source: item.source,
            phone: Kit.Text.truncate(item.phone, limit: 64),
            checksum: Kit.Text.truncate(item.checksum, limit: 64),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessBatchViews(_ items: [WitnessBatch]) -> [WitnessBatchView] {
        var views: [WitnessBatchView] = []
        for item in items {
            views.append(toWitnessBatchView(item))
        }
        return views
    }

    static func sumWitnessBatchView(_ view: WitnessBatchView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedVersion) + parsedCeiling
    }
}
