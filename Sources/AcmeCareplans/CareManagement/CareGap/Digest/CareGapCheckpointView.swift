import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap checkpoint.
    final class CareGapCheckpointView {
        var code: String
        var name: String
        var discount: String
        var priority: String
        var category: String
        var active: String
        var ownerID: String
        var endsAtText: String
        var statusLabel: String

        init(code: String, name: String, discount: String, priority: String, category: String, active: String, ownerID: String, endsAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.discount = discount
            self.priority = priority
            self.category = category
            self.active = active
            self.ownerID = ownerID
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapCheckpointView(_ item: CareGapCheckpoint) -> CareGapCheckpointView {
        return CareGapCheckpointView(
            code: item.code,
            name: item.name,
            discount: String(format: "%.2f", item.discount),
            priority: String(item.priority),
            category: Kit.Text.truncate(item.category, limit: 64),
            active: "\(item.active)",
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapCheckpointViews(_ items: [CareGapCheckpoint]) -> [CareGapCheckpointView] {
        var views: [CareGapCheckpointView] = []
        for item in items {
            views.append(toCareGapCheckpointView(item))
        }
        return views
    }

    static func sumCareGapCheckpointView(_ view: CareGapCheckpointView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedDiscount + Double(parsedPriority) + Double(parsedEndsAt)
    }
}
