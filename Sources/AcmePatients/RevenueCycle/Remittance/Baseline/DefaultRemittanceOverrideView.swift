import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a default remittance override.
    final class DefaultRemittanceOverrideView {
        var codeText: String
        var name: String
        var bed: String
        var encounterID: String
        var batchSize: String
        var createdAt: String
        var source: String
        var statusLabel: String

        init(codeText: String, name: String, bed: String, encounterID: String, batchSize: String, createdAt: String, source: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.bed = bed
            self.encounterID = encounterID
            self.batchSize = batchSize
            self.createdAt = createdAt
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultRemittanceOverrideView(_ item: DefaultRemittanceOverride) -> DefaultRemittanceOverrideView {
        return DefaultRemittanceOverrideView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            bed: Kit.Text.truncate(item.bed, limit: 120),
            encounterID: item.encounterID,
            batchSize: String(item.batchSize),
            createdAt: String(item.createdAt),
            source: Kit.Text.truncate(item.source, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultRemittanceOverrideViews(_ items: [DefaultRemittanceOverride]) -> [DefaultRemittanceOverrideView] {
        var views: [DefaultRemittanceOverrideView] = []
        for item in items {
            views.append(toDefaultRemittanceOverrideView(item))
        }
        return views
    }

    static func sumDefaultRemittanceOverrideView(_ view: DefaultRemittanceOverrideView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedCreatedAt)
    }
}
