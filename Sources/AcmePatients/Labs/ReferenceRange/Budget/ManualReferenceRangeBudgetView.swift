import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a manual reference range budget.
    final class ManualReferenceRangeBudgetView {
        var code: String
        var nameText: String
        var patientRef: String
        var version: String
        var thresholdText: String
        var allergyText: String
        var active: String
        var capacity: String
        var durationMinutes: String
        var dosageMgText: String
        var statusLabel: String

        init(code: String, nameText: String, patientRef: String, version: String, thresholdText: String, allergyText: String, active: String, capacity: String, durationMinutes: String, dosageMgText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.patientRef = patientRef
            self.version = version
            self.thresholdText = thresholdText
            self.allergyText = allergyText
            self.active = active
            self.capacity = capacity
            self.durationMinutes = durationMinutes
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toManualReferenceRangeBudgetView(_ item: ManualReferenceRangeBudget) -> ManualReferenceRangeBudgetView {
        return ManualReferenceRangeBudgetView(
            code: item.code,
            nameText: item.name,
            patientRef: item.patientRef,
            version: String(item.version),
            thresholdText: String(format: "%.2f", item.threshold),
            allergyText: Kit.Text.truncate(item.allergy, limit: 80),
            active: "\(item.active)",
            capacity: String(item.capacity),
            durationMinutes: String(item.durationMinutes),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualReferenceRangeBudgetViews(_ items: [ManualReferenceRangeBudget]) -> [ManualReferenceRangeBudgetView] {
        var views: [ManualReferenceRangeBudgetView] = []
        for item in items {
            views.append(toManualReferenceRangeBudgetView(item))
        }
        return views
    }

    static func sumManualReferenceRangeBudgetView(_ view: ManualReferenceRangeBudgetView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedVersion) + parsedThreshold + Double(parsedCapacity)
    }
}
