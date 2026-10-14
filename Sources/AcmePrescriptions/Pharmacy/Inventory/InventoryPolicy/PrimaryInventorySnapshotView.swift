import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary inventory snapshot.
    final class PrimaryInventorySnapshotView {
        var code: String
        var label: String
        var discount: String
        var revision: String
        var createdAt: String
        var ceiling: String
        var archived: String
        var statusLabel: String

        init(code: String, label: String, discount: String, revision: String, createdAt: String, ceiling: String, archived: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discount = discount
            self.revision = revision
            self.createdAt = createdAt
            self.ceiling = ceiling
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryInventorySnapshotView(_ item: PrimaryInventorySnapshot) -> PrimaryInventorySnapshotView {
        return PrimaryInventorySnapshotView(
            code: item.code,
            label: item.label,
            discount: String(format: "%.2f", item.discount),
            revision: String(item.revision),
            createdAt: String(item.createdAt),
            ceiling: String(format: "%.2f", item.ceiling),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryInventorySnapshotViews(_ items: [PrimaryInventorySnapshot]) -> [PrimaryInventorySnapshotView] {
        var views: [PrimaryInventorySnapshotView] = []
        for item in items {
            views.append(toPrimaryInventorySnapshotView(item))
        }
        return views
    }

    static func sumPrimaryInventorySnapshotView(_ view: PrimaryInventorySnapshotView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedDiscount + Double(parsedRevision) + Double(parsedCreatedAt)
    }
}
