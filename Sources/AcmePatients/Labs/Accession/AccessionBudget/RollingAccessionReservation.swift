import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling accession reservation is in its life cycle.
    enum RollingAccessionReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a rolling accession reservation and its current status.
    final class RollingAccessionReservation {
        var code: String
        var label: String
        var active: Bool
        var unit: String
        var threshold: Double
        var status: RollingAccessionReservationStatus

        init(code: String, label: String, active: Bool, unit: String, threshold: Double, status: RollingAccessionReservationStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.unit = unit
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingAccessionReservationStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingAccessionReservationStatus.scheduled || next == RollingAccessionReservationStatus.cancelled
            case .scheduled:
                return next == RollingAccessionReservationStatus.completed
            case .inProgress:
                return next == RollingAccessionReservationStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingAccessionReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling accession reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> RollingAccessionReservation {
            return RollingAccessionReservation(
                code: code,
                label: label,
                active: active,
                unit: unit,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a rolling accession reservation in status planned.
    static func newRollingAccessionReservation(_ code: String, label: String) -> RollingAccessionReservation {
        return RollingAccessionReservation(
            code: code,
            label: label,
            active: false,
            unit: "",
            threshold: 0.0,
            status: RollingAccessionReservationStatus.planned
        )
    }
}
