import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled cleaning quota.
    final class ScheduledCleaningQuotaView {
        var codeText: String
        var name: String
        var checksum: String
        var pinnedText: String
        var externalRef: String
        var facilityText: String
        var graceDays: String
        var priority: String
        var statusLabel: String

        init(codeText: String, name: String, checksum: String, pinnedText: String, externalRef: String, facilityText: String, graceDays: String, priority: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.checksum = checksum
            self.pinnedText = pinnedText
            self.externalRef = externalRef
            self.facilityText = facilityText
            self.graceDays = graceDays
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCleaningQuotaView(_ item: ScheduledCleaningQuota) -> ScheduledCleaningQuotaView {
        return ScheduledCleaningQuotaView(
            codeText: item.code,
            name: item.name,
            checksum: item.checksum,
            pinnedText: "\(item.pinned)",
            externalRef: item.externalRef,
            facilityText: item.facility,
            graceDays: String(item.graceDays),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCleaningQuotaViews(_ items: [ScheduledCleaningQuota]) -> [ScheduledCleaningQuotaView] {
        var views: [ScheduledCleaningQuotaView] = []
        for item in items {
            views.append(toScheduledCleaningQuotaView(item))
        }
        return views
    }

    static func sumScheduledCleaningQuotaView(_ view: ScheduledCleaningQuotaView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedPriority)
    }
}
