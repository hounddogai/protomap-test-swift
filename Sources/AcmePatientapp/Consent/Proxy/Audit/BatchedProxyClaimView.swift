import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched proxy claim.
    final class BatchedProxyClaimView {
        var code: String
        var label: String
        var revisionText: String
        var capacityText: String
        var createdAt: String
        var phone: String
        var amountText: String
        var source: String
        var statusLabel: String

        init(code: String, label: String, revisionText: String, capacityText: String, createdAt: String, phone: String, amountText: String, source: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.revisionText = revisionText
            self.capacityText = capacityText
            self.createdAt = createdAt
            self.phone = phone
            self.amountText = amountText
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedProxyClaimView(_ item: BatchedProxyClaim) -> BatchedProxyClaimView {
        return BatchedProxyClaimView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            revisionText: String(item.revision),
            capacityText: String(item.capacity),
            createdAt: String(item.createdAt),
            phone: item.phone,
            amountText: String(format: "%.2f", item.amount),
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedProxyClaimViews(_ items: [BatchedProxyClaim]) -> [BatchedProxyClaimView] {
        var views: [BatchedProxyClaimView] = []
        for item in items {
            views.append(toBatchedProxyClaimView(item))
        }
        return views
    }

    static func sumBatchedProxyClaimView(_ view: BatchedProxyClaimView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedRevision) + Double(parsedCapacity) + Double(parsedCreatedAt)
    }
}
