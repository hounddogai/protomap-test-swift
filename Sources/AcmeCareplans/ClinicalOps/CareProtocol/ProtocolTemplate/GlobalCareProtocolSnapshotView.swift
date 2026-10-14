import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a global care protocol snapshot.
    final class GlobalCareProtocolSnapshotView {
        var code: String
        var nameText: String
        var capacity: String
        var checksum: String
        var region: String
        var endsAtText: String
        var reviewer: String
        var priority: String
        var statusLabel: String

        init(code: String, nameText: String, capacity: String, checksum: String, region: String, endsAtText: String, reviewer: String, priority: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.capacity = capacity
            self.checksum = checksum
            self.region = region
            self.endsAtText = endsAtText
            self.reviewer = reviewer
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCareProtocolSnapshotView(_ item: GlobalCareProtocolSnapshot) -> GlobalCareProtocolSnapshotView {
        return GlobalCareProtocolSnapshotView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            capacity: String(item.capacity),
            checksum: item.checksum,
            region: Kit.Text.truncate(item.region, limit: 120),
            endsAtText: String(item.endsAt),
            reviewer: item.reviewer,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCareProtocolSnapshotViews(_ items: [GlobalCareProtocolSnapshot]) -> [GlobalCareProtocolSnapshotView] {
        var views: [GlobalCareProtocolSnapshotView] = []
        for item in items {
            views.append(toGlobalCareProtocolSnapshotView(item))
        }
        return views
    }

    static func sumGlobalCareProtocolSnapshotView(_ view: GlobalCareProtocolSnapshotView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedCapacity) + Double(parsedEndsAt) + Double(parsedPriority)
    }
}
