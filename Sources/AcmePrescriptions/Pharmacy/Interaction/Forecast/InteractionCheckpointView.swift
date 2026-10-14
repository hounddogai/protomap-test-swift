import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction checkpoint.
    final class InteractionCheckpointView {
        var code: String
        var name: String
        var ward: String
        var pinnedText: String
        var weightText: String
        var facility: String
        var limit: String
        var ceiling: String
        var attempts: String
        var quantity: String
        var statusLabel: String

        init(code: String, name: String, ward: String, pinnedText: String, weightText: String, facility: String, limit: String, ceiling: String, attempts: String, quantity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ward = ward
            self.pinnedText = pinnedText
            self.weightText = weightText
            self.facility = facility
            self.limit = limit
            self.ceiling = ceiling
            self.attempts = attempts
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionCheckpointView(_ item: InteractionCheckpoint) -> InteractionCheckpointView {
        return InteractionCheckpointView(
            code: item.code,
            name: item.name,
            ward: item.ward,
            pinnedText: "\(item.pinned)",
            weightText: String(format: "%.2f", item.weight),
            facility: item.facility,
            limit: String(item.limit),
            ceiling: String(format: "%.2f", item.ceiling),
            attempts: String(item.attempts),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionCheckpointViews(_ items: [InteractionCheckpoint]) -> [InteractionCheckpointView] {
        var views: [InteractionCheckpointView] = []
        for item in items {
            views.append(toInteractionCheckpointView(item))
        }
        return views
    }

    static func sumInteractionCheckpointView(_ view: InteractionCheckpointView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedWeight + Double(parsedLimit) + parsedCeiling
    }
}
