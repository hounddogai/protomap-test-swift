import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual dispense mapping.
    final class ManualDispenseMappingView {
        var codeText: String
        var label: String
        var ward: String
        var region: String
        var attemptsText: String
        var summary: String
        var description: String
        var active: String
        var clinicianID: String
        var budget: String
        var visible: String
        var statusLabel: String

        init(codeText: String, label: String, ward: String, region: String, attemptsText: String, summary: String, description: String, active: String, clinicianID: String, budget: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ward = ward
            self.region = region
            self.attemptsText = attemptsText
            self.summary = summary
            self.description = description
            self.active = active
            self.clinicianID = clinicianID
            self.budget = budget
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toManualDispenseMappingView(_ item: ManualDispenseMapping) -> ManualDispenseMappingView {
        return ManualDispenseMappingView(
            codeText: item.code,
            label: item.label,
            ward: Kit.Text.truncate(item.ward, limit: 40),
            region: item.region,
            attemptsText: String(item.attempts),
            summary: item.summary,
            description: item.description,
            active: "\(item.active)",
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 120),
            budget: String(format: "%.2f", item.budget),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualDispenseMappingViews(_ items: [ManualDispenseMapping]) -> [ManualDispenseMappingView] {
        var views: [ManualDispenseMappingView] = []
        for item in items {
            views.append(toManualDispenseMappingView(item))
        }
        return views
    }

    static func sumManualDispenseMappingView(_ view: ManualDispenseMappingView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedAttempts) + parsedBudget
    }
}
