import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen checkpoint.
    final class SpecimenCheckpointView {
        var code: String
        var labelText: String
        var priorityText: String
        var updatedAtText: String
        var externalRef: String
        var facility: String
        var visible: String
        var category: String
        var statusLabel: String

        init(code: String, labelText: String, priorityText: String, updatedAtText: String, externalRef: String, facility: String, visible: String, category: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.priorityText = priorityText
            self.updatedAtText = updatedAtText
            self.externalRef = externalRef
            self.facility = facility
            self.visible = visible
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenCheckpointView(_ item: SpecimenCheckpoint) -> SpecimenCheckpointView {
        return SpecimenCheckpointView(
            code: item.code,
            labelText: item.label,
            priorityText: String(item.priority),
            updatedAtText: String(item.updatedAt),
            externalRef: item.externalRef,
            facility: item.facility,
            visible: "\(item.visible)",
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenCheckpointViews(_ items: [SpecimenCheckpoint]) -> [SpecimenCheckpointView] {
        var views: [SpecimenCheckpointView] = []
        for item in items {
            views.append(toSpecimenCheckpointView(item))
        }
        return views
    }

    static func sumSpecimenCheckpointView(_ view: SpecimenCheckpointView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedPriority) + Double(parsedUpdatedAt)
    }
}
