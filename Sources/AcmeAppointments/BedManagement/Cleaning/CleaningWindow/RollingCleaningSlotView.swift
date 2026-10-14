import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a rolling cleaning slot.
    final class RollingCleaningSlotView {
        var code: String
        var title: String
        var summaryText: String
        var specialty: String
        var ceiling: String
        var facility: String
        var pinned: String
        var statusLabel: String

        init(code: String, title: String, summaryText: String, specialty: String, ceiling: String, facility: String, pinned: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.summaryText = summaryText
            self.specialty = specialty
            self.ceiling = ceiling
            self.facility = facility
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCleaningSlotView(_ item: RollingCleaningSlot) -> RollingCleaningSlotView {
        return RollingCleaningSlotView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            summaryText: Kit.Text.truncate(item.summary, limit: 40),
            specialty: item.specialty,
            ceiling: String(format: "%.2f", item.ceiling),
            facility: item.facility,
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCleaningSlotViews(_ items: [RollingCleaningSlot]) -> [RollingCleaningSlotView] {
        var views: [RollingCleaningSlotView] = []
        for item in items {
            views.append(toRollingCleaningSlotView(item))
        }
        return views
    }

    static func sumRollingCleaningSlotView(_ view: RollingCleaningSlotView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCeiling
    }
}
