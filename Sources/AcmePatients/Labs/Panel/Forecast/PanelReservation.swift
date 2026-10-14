import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel reservation is in its life cycle.
    enum PanelReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a panel reservation and its current status.
    final class PanelReservation {
        var code: String
        var title: String
        var bed: String
        var description: String
        var ratio: Double
        var dosageMg: Double
        var capacity: Int
        var maximum: Double
        var unit: String
        var status: PanelReservationStatus

        init(code: String, title: String, bed: String, description: String, ratio: Double, dosageMg: Double, capacity: Int, maximum: Double, unit: String, status: PanelReservationStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.description = description
            self.ratio = ratio
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.maximum = maximum
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PanelReservationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PanelReservationStatus.inReview
            case .inReview:
                return next == PanelReservationStatus.resolved || next == PanelReservationStatus.reopened
            case .resolved:
                return next == PanelReservationStatus.reopened || next == PanelReservationStatus.archived
            case .reopened:
                return next == PanelReservationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("panel reservation") \(code)"
        }

        func weightedExposure() -> Double {
            return ((dosageMg - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> PanelReservation {
            return PanelReservation(
                code: code,
                title: title,
                bed: bed,
                description: description,
                ratio: ratio,
                dosageMg: dosageMg,
                capacity: capacity,
                maximum: maximum,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a panel reservation in status open.
    static func newPanelReservation(_ code: String, title: String) -> PanelReservation {
        return PanelReservation(
            code: code,
            title: title,
            bed: "",
            description: "",
            ratio: 0.0,
            dosageMg: 0.0,
            capacity: 0,
            maximum: 0.0,
            unit: "",
            status: PanelReservationStatus.`open`
        )
    }
}
