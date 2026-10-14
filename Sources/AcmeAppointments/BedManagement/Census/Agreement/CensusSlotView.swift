import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census slot.
    final class CensusSlotView {
        var codeText: String
        var labelText: String
        var locale: String
        var quantity: String
        var minimum: String
        var active: String
        var createdAt: String
        var specialtyText: String
        var ward: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, labelText: String, locale: String, quantity: String, minimum: String, active: String, createdAt: String, specialtyText: String, ward: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.locale = locale
            self.quantity = quantity
            self.minimum = minimum
            self.active = active
            self.createdAt = createdAt
            self.specialtyText = specialtyText
            self.ward = ward
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toCensusSlotView(_ item: CensusSlot) -> CensusSlotView {
        return CensusSlotView(
            codeText: item.code,
            labelText: item.label,
            locale: item.locale,
            quantity: String(item.quantity),
            minimum: String(format: "%.2f", item.minimum),
            active: "\(item.active)",
            createdAt: String(item.createdAt),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 40),
            ward: item.ward,
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusSlotViews(_ items: [CensusSlot]) -> [CensusSlotView] {
        var views: [CensusSlotView] = []
        for item in items {
            views.append(toCensusSlotView(item))
        }
        return views
    }

    static func sumCensusSlotView(_ view: CensusSlotView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedQuantity) + parsedMinimum + Double(parsedCreatedAt)
    }
}
