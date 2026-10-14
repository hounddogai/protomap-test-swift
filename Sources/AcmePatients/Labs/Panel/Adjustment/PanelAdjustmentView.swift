import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel adjustment.
    final class PanelAdjustmentView {
        var code: String
        var name: String
        var externalRef: String
        var source: String
        var specialty: String
        var budget: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, name: String, externalRef: String, source: String, specialty: String, budget: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.source = source
            self.specialty = specialty
            self.budget = budget
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toPanelAdjustmentView(_ item: PanelAdjustment) -> PanelAdjustmentView {
        return PanelAdjustmentView(
            code: item.code,
            name: item.name,
            externalRef: item.externalRef,
            source: item.source,
            specialty: item.specialty,
            budget: String(format: "%.2f", item.budget),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelAdjustmentViews(_ items: [PanelAdjustment]) -> [PanelAdjustmentView] {
        var views: [PanelAdjustmentView] = []
        for item in items {
            views.append(toPanelAdjustmentView(item))
        }
        return views
    }

    static func sumPanelAdjustmentView(_ view: PanelAdjustmentView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedBudget + Double(parsedDurationMinutes)
    }
}
