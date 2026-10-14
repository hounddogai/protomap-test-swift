import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered program preference.
    final class TieredProgramPreferenceView {
        var code: String
        var nameText: String
        var ceiling: String
        var titleText: String
        var label: String
        var capacity: String
        var attempts: String
        var approved: String
        var floorValue: String
        var statusLabel: String

        init(code: String, nameText: String, ceiling: String, titleText: String, label: String, capacity: String, attempts: String, approved: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ceiling = ceiling
            self.titleText = titleText
            self.label = label
            self.capacity = capacity
            self.attempts = attempts
            self.approved = approved
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toTieredProgramPreferenceView(_ item: TieredProgramPreference) -> TieredProgramPreferenceView {
        return TieredProgramPreferenceView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            ceiling: String(format: "%.2f", item.ceiling),
            titleText: item.title,
            label: item.label,
            capacity: String(item.capacity),
            attempts: String(item.attempts),
            approved: "\(item.approved)",
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredProgramPreferenceViews(_ items: [TieredProgramPreference]) -> [TieredProgramPreferenceView] {
        var views: [TieredProgramPreferenceView] = []
        for item in items {
            views.append(toTieredProgramPreferenceView(item))
        }
        return views
    }

    static func sumTieredProgramPreferenceView(_ view: TieredProgramPreferenceView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedCeiling + Double(parsedCapacity) + Double(parsedAttempts)
    }
}
