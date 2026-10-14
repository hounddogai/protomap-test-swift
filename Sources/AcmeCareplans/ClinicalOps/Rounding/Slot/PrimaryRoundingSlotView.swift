import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary rounding slot.
    final class PrimaryRoundingSlotView {
        var code: String
        var name: String
        var notes: String
        var pinned: String
        var retries: String
        var rate: String
        var weight: String
        var active: String
        var windowDays: String
        var specialtyText: String
        var statusLabel: String

        init(code: String, name: String, notes: String, pinned: String, retries: String, rate: String, weight: String, active: String, windowDays: String, specialtyText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.notes = notes
            self.pinned = pinned
            self.retries = retries
            self.rate = rate
            self.weight = weight
            self.active = active
            self.windowDays = windowDays
            self.specialtyText = specialtyText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryRoundingSlotView(_ item: PrimaryRoundingSlot) -> PrimaryRoundingSlotView {
        return PrimaryRoundingSlotView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 40),
            notes: Kit.Text.truncate(item.notes, limit: 80),
            pinned: "\(item.pinned)",
            retries: String(item.retries),
            rate: String(format: "%.2f", item.rate),
            weight: String(format: "%.2f", item.weight),
            active: "\(item.active)",
            windowDays: String(item.windowDays),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryRoundingSlotViews(_ items: [PrimaryRoundingSlot]) -> [PrimaryRoundingSlotView] {
        var views: [PrimaryRoundingSlotView] = []
        for item in items {
            views.append(toPrimaryRoundingSlotView(item))
        }
        return views
    }

    static func sumPrimaryRoundingSlotView(_ view: PrimaryRoundingSlotView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedRetries) + parsedRate + parsedWeight
    }
}
