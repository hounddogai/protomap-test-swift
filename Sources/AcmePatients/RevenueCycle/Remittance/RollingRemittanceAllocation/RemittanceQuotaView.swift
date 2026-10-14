import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance quota.
    final class RemittanceQuotaView {
        var codeText: String
        var nameText: String
        var approved: String
        var batchSize: String
        var capacity: String
        var pinned: String
        var createdAt: String
        var reviewer: String
        var statusLabel: String

        init(codeText: String, nameText: String, approved: String, batchSize: String, capacity: String, pinned: String, createdAt: String, reviewer: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.approved = approved
            self.batchSize = batchSize
            self.capacity = capacity
            self.pinned = pinned
            self.createdAt = createdAt
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceQuotaView(_ item: RemittanceQuota) -> RemittanceQuotaView {
        return RemittanceQuotaView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            approved: "\(item.approved)",
            batchSize: String(item.batchSize),
            capacity: String(item.capacity),
            pinned: "\(item.pinned)",
            createdAt: String(item.createdAt),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceQuotaViews(_ items: [RemittanceQuota]) -> [RemittanceQuotaView] {
        var views: [RemittanceQuotaView] = []
        for item in items {
            views.append(toRemittanceQuotaView(item))
        }
        return views
    }

    static func sumRemittanceQuotaView(_ view: RemittanceQuotaView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedCapacity) + Double(parsedCreatedAt)
    }
}
