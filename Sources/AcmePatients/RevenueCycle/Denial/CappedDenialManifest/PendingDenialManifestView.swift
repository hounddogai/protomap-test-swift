import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a pending denial manifest.
    final class PendingDenialManifestView {
        var code: String
        var title: String
        var batchSize: String
        var approved: String
        var name: String
        var cost: String
        var contactEmail: String
        var createdAt: String
        var label: String
        var statusLabel: String

        init(code: String, title: String, batchSize: String, approved: String, name: String, cost: String, contactEmail: String, createdAt: String, label: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.approved = approved
            self.name = name
            self.cost = cost
            self.contactEmail = contactEmail
            self.createdAt = createdAt
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toPendingDenialManifestView(_ item: PendingDenialManifest) -> PendingDenialManifestView {
        return PendingDenialManifestView(
            code: item.code,
            title: item.title,
            batchSize: String(item.batchSize),
            approved: "\(item.approved)",
            name: item.name,
            cost: String(format: "%.2f", item.cost),
            contactEmail: item.contactEmail,
            createdAt: String(item.createdAt),
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingDenialManifestViews(_ items: [PendingDenialManifest]) -> [PendingDenialManifestView] {
        var views: [PendingDenialManifestView] = []
        for item in items {
            views.append(toPendingDenialManifestView(item))
        }
        return views
    }

    static func sumPendingDenialManifestView(_ view: PendingDenialManifestView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedBatchSize) + parsedCost + Double(parsedCreatedAt)
    }
}
