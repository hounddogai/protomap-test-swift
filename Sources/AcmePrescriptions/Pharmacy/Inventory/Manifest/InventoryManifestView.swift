import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory manifest.
    final class InventoryManifestView {
        var code: String
        var title: String
        var sourceText: String
        var refills: String
        var capacity: String
        var reviewer: String
        var checksum: String
        var statusLabel: String

        init(code: String, title: String, sourceText: String, refills: String, capacity: String, reviewer: String, checksum: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sourceText = sourceText
            self.refills = refills
            self.capacity = capacity
            self.reviewer = reviewer
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryManifestView(_ item: InventoryManifest) -> InventoryManifestView {
        return InventoryManifestView(
            code: item.code,
            title: item.title,
            sourceText: item.source,
            refills: String(item.refills),
            capacity: String(item.capacity),
            reviewer: item.reviewer,
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryManifestViews(_ items: [InventoryManifest]) -> [InventoryManifestView] {
        var views: [InventoryManifestView] = []
        for item in items {
            views.append(toInventoryManifestView(item))
        }
        return views
    }

    static func sumInventoryManifestView(_ view: InventoryManifestView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedRefills) + Double(parsedCapacity)
    }
}
