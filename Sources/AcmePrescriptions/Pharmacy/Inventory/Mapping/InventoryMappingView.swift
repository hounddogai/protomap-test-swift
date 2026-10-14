import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory mapping.
    final class InventoryMappingView {
        var codeText: String
        var titleText: String
        var durationMinutes: String
        var refills: String
        var archived: String
        var notes: String
        var startsAt: String
        var statusLabel: String

        init(codeText: String, titleText: String, durationMinutes: String, refills: String, archived: String, notes: String, startsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.durationMinutes = durationMinutes
            self.refills = refills
            self.archived = archived
            self.notes = notes
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryMappingView(_ item: InventoryMapping) -> InventoryMappingView {
        return InventoryMappingView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            durationMinutes: String(item.durationMinutes),
            refills: String(item.refills),
            archived: "\(item.archived)",
            notes: item.notes,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryMappingViews(_ items: [InventoryMapping]) -> [InventoryMappingView] {
        var views: [InventoryMappingView] = []
        for item in items {
            views.append(toInventoryMappingView(item))
        }
        return views
    }

    static func sumInventoryMappingView(_ view: InventoryMappingView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedRefills) + Double(parsedStartsAt)
    }
}
