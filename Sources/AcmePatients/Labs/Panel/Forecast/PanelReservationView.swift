import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel reservation.
    final class PanelReservationView {
        var code: String
        var title: String
        var bedText: String
        var descriptionText: String
        var ratio: String
        var dosageMg: String
        var capacity: String
        var maximum: String
        var unitText: String
        var statusLabel: String

        init(code: String, title: String, bedText: String, descriptionText: String, ratio: String, dosageMg: String, capacity: String, maximum: String, unitText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.bedText = bedText
            self.descriptionText = descriptionText
            self.ratio = ratio
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.maximum = maximum
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toPanelReservationView(_ item: PanelReservation) -> PanelReservationView {
        return PanelReservationView(
            code: item.code,
            title: item.title,
            bedText: item.bed,
            descriptionText: item.description,
            ratio: String(format: "%.2f", item.ratio),
            dosageMg: String(format: "%.2f", item.dosageMg),
            capacity: String(item.capacity),
            maximum: String(format: "%.2f", item.maximum),
            unitText: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelReservationViews(_ items: [PanelReservation]) -> [PanelReservationView] {
        var views: [PanelReservationView] = []
        for item in items {
            views.append(toPanelReservationView(item))
        }
        return views
    }

    static func sumPanelReservationView(_ view: PanelReservationView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedRatio + parsedDosageMg + Double(parsedCapacity)
    }
}
