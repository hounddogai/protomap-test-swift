import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a manual care protocol reservation.
    final class ManualCareProtocolReservationView {
        var code: String
        var label: String
        var name: String
        var reviewer: String
        var floorValue: String
        var sequence: String
        var weightText: String
        var statusLabel: String

        init(code: String, label: String, name: String, reviewer: String, floorValue: String, sequence: String, weightText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.name = name
            self.reviewer = reviewer
            self.floorValue = floorValue
            self.sequence = sequence
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toManualCareProtocolReservationView(_ item: ManualCareProtocolReservation) -> ManualCareProtocolReservationView {
        return ManualCareProtocolReservationView(
            code: item.code,
            label: item.label,
            name: item.name,
            reviewer: item.reviewer,
            floorValue: String(format: "%.2f", item.floorValue),
            sequence: String(item.sequence),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCareProtocolReservationViews(_ items: [ManualCareProtocolReservation]) -> [ManualCareProtocolReservationView] {
        var views: [ManualCareProtocolReservationView] = []
        for item in items {
            views.append(toManualCareProtocolReservationView(item))
        }
        return views
    }

    static func sumManualCareProtocolReservationView(_ view: ManualCareProtocolReservationView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedFloorValue + Double(parsedSequence) + parsedWeight
    }
}
