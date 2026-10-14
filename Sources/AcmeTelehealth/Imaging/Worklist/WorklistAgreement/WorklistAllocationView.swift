import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist allocation.
    final class WorklistAllocationView {
        var code: String
        var name: String
        var patientRef: String
        var regionText: String
        var quantity: String
        var encounterIDText: String
        var cost: String
        var clinicianIDText: String
        var expiresAt: String
        var limit: String
        var visible: String
        var statusLabel: String

        init(code: String, name: String, patientRef: String, regionText: String, quantity: String, encounterIDText: String, cost: String, clinicianIDText: String, expiresAt: String, limit: String, visible: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.regionText = regionText
            self.quantity = quantity
            self.encounterIDText = encounterIDText
            self.cost = cost
            self.clinicianIDText = clinicianIDText
            self.expiresAt = expiresAt
            self.limit = limit
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistAllocationView(_ item: WorklistAllocation) -> WorklistAllocationView {
        return WorklistAllocationView(
            code: item.code,
            name: item.name,
            patientRef: item.patientRef,
            regionText: item.region,
            quantity: String(item.quantity),
            encounterIDText: item.encounterID,
            cost: String(format: "%.2f", item.cost),
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 64),
            expiresAt: String(item.expiresAt),
            limit: String(item.limit),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistAllocationViews(_ items: [WorklistAllocation]) -> [WorklistAllocationView] {
        var views: [WorklistAllocationView] = []
        for item in items {
            views.append(toWorklistAllocationView(item))
        }
        return views
    }

    static func sumWorklistAllocationView(_ view: WorklistAllocationView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedQuantity) + parsedCost + Double(parsedExpiresAt)
    }
}
