import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier slot.
    final class CourierSlotView {
        var code: String
        var nameText: String
        var segment: String
        var durationMinutes: String
        var unitText: String
        var quantity: String
        var capacity: String
        var statusLabel: String

        init(code: String, nameText: String, segment: String, durationMinutes: String, unitText: String, quantity: String, capacity: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.segment = segment
            self.durationMinutes = durationMinutes
            self.unitText = unitText
            self.quantity = quantity
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toCourierSlotView(_ item: CourierSlot) -> CourierSlotView {
        return CourierSlotView(
            code: item.code,
            nameText: item.name,
            segment: item.segment,
            durationMinutes: String(item.durationMinutes),
            unitText: item.unit,
            quantity: String(item.quantity),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierSlotViews(_ items: [CourierSlot]) -> [CourierSlotView] {
        var views: [CourierSlotView] = []
        for item in items {
            views.append(toCourierSlotView(item))
        }
        return views
    }

    static func sumCourierSlotView(_ view: CourierSlotView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedQuantity) + Double(parsedCapacity)
    }
}
