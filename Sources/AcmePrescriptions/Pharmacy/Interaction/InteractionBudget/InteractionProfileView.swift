import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction profile.
    final class InteractionProfileView {
        var codeText: String
        var name: String
        var pinned: String
        var weight: String
        var specialtyText: String
        var phone: String
        var unitText: String
        var priority: String
        var statusLabel: String

        init(codeText: String, name: String, pinned: String, weight: String, specialtyText: String, phone: String, unitText: String, priority: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.pinned = pinned
            self.weight = weight
            self.specialtyText = specialtyText
            self.phone = phone
            self.unitText = unitText
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionProfileView(_ item: InteractionProfile) -> InteractionProfileView {
        return InteractionProfileView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            pinned: "\(item.pinned)",
            weight: String(format: "%.2f", item.weight),
            specialtyText: item.specialty,
            phone: item.phone,
            unitText: Kit.Text.truncate(item.unit, limit: 40),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionProfileViews(_ items: [InteractionProfile]) -> [InteractionProfileView] {
        var views: [InteractionProfileView] = []
        for item in items {
            views.append(toInteractionProfileView(item))
        }
        return views
    }

    static func sumInteractionProfileView(_ view: InteractionProfileView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedWeight + Double(parsedPriority)
    }
}
