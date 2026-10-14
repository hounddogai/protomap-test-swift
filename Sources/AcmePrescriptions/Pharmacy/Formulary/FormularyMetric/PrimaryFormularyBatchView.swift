import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary formulary batch.
    final class PrimaryFormularyBatchView {
        var code: String
        var titleText: String
        var facility: String
        var ward: String
        var quantity: String
        var createdAt: String
        var weight: String
        var encounterIDText: String
        var visible: String
        var margin: String
        var statusLabel: String

        init(code: String, titleText: String, facility: String, ward: String, quantity: String, createdAt: String, weight: String, encounterIDText: String, visible: String, margin: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.facility = facility
            self.ward = ward
            self.quantity = quantity
            self.createdAt = createdAt
            self.weight = weight
            self.encounterIDText = encounterIDText
            self.visible = visible
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryFormularyBatchView(_ item: PrimaryFormularyBatch) -> PrimaryFormularyBatchView {
        return PrimaryFormularyBatchView(
            code: item.code,
            titleText: item.title,
            facility: item.facility,
            ward: item.ward,
            quantity: String(item.quantity),
            createdAt: String(item.createdAt),
            weight: String(format: "%.2f", item.weight),
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 120),
            visible: "\(item.visible)",
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryFormularyBatchViews(_ items: [PrimaryFormularyBatch]) -> [PrimaryFormularyBatchView] {
        var views: [PrimaryFormularyBatchView] = []
        for item in items {
            views.append(toPrimaryFormularyBatchView(item))
        }
        return views
    }

    static func sumPrimaryFormularyBatchView(_ view: PrimaryFormularyBatchView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedQuantity) + Double(parsedCreatedAt) + parsedWeight
    }
}
