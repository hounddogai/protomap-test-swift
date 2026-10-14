import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census cycle.
    final class CensusCycleView {
        var code: String
        var name: String
        var label: String
        var ownerIDText: String
        var refills: String
        var priorityText: String
        var dosageMgText: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, name: String, label: String, ownerIDText: String, refills: String, priorityText: String, dosageMgText: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.label = label
            self.ownerIDText = ownerIDText
            self.refills = refills
            self.priorityText = priorityText
            self.dosageMgText = dosageMgText
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toCensusCycleView(_ item: CensusCycle) -> CensusCycleView {
        return CensusCycleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            label: Kit.Text.truncate(item.label, limit: 120),
            ownerIDText: item.ownerID,
            refills: String(item.refills),
            priorityText: String(item.priority),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            clinicianIDText: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusCycleViews(_ items: [CensusCycle]) -> [CensusCycleView] {
        var views: [CensusCycleView] = []
        for item in items {
            views.append(toCensusCycleView(item))
        }
        return views
    }

    static func sumCensusCycleView(_ view: CensusCycleView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedRefills) + Double(parsedPriority) + parsedDosageMg
    }
}
