import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a global priority quota.
    final class GlobalPriorityQuotaView {
        var code: String
        var label: String
        var notes: String
        var updatedAt: String
        var encounterID: String
        var checksum: String
        var segment: String
        var statusLabel: String

        init(code: String, label: String, notes: String, updatedAt: String, encounterID: String, checksum: String, segment: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.notes = notes
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.checksum = checksum
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalPriorityQuotaView(_ item: GlobalPriorityQuota) -> GlobalPriorityQuotaView {
        return GlobalPriorityQuotaView(
            code: item.code,
            label: item.label,
            notes: item.notes,
            updatedAt: String(item.updatedAt),
            encounterID: item.encounterID,
            checksum: item.checksum,
            segment: Kit.Text.truncate(item.segment, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalPriorityQuotaViews(_ items: [GlobalPriorityQuota]) -> [GlobalPriorityQuotaView] {
        var views: [GlobalPriorityQuotaView] = []
        for item in items {
            views.append(toGlobalPriorityQuotaView(item))
        }
        return views
    }

    static func sumGlobalPriorityQuotaView(_ view: GlobalPriorityQuotaView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
