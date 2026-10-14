import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool reservation is in its life cycle.
    enum FloatPoolReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One float pool reservation, with what the planners need to act on it.
    final class FloatPoolReservation {
        var code: String
        var name: String
        var label: String
        var score: Double
        var source: String
        var minimum: Double
        var specialty: String
        var channel: String
        var status: FloatPoolReservationStatus

        init(code: String, name: String, label: String, score: Double, source: String, minimum: Double, specialty: String, channel: String, status: FloatPoolReservationStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.score = score
            self.source = source
            self.minimum = minimum
            self.specialty = specialty
            self.channel = channel
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

        func canMoveTo(_ next: FloatPoolReservationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == FloatPoolReservationStatus.cancelled
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

        func moveTo(_ next: FloatPoolReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func effectiveExposure() -> Double {
            return ((score + minimum) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolReservation {
            return FloatPoolReservation(
                code: code,
                name: name,
                label: label,
                score: score,
                source: source,
                minimum: minimum,
                specialty: specialty,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a float pool reservation in status planned.
    static func newFloatPoolReservation(_ code: String, name: String) -> FloatPoolReservation {
        return FloatPoolReservation(
            code: code,
            name: name,
            label: "",
            score: 0.0,
            source: "",
            minimum: 0.0,
            specialty: "",
            channel: "",
            status: FloatPoolReservationStatus.planned
        )
    }
}
