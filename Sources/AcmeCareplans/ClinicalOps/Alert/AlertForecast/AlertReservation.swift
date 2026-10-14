import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert reservation is in its life cycle.
    enum AlertReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A alert reservation. Its code is unique within a tenant.
    final class AlertReservation {
        var code: String
        var title: String
        var bed: String
        var segment: String
        var channel: String
        var attempts: Int
        var sequence: Int
        var rate: Double
        var status: AlertReservationStatus

        init(code: String, title: String, bed: String, segment: String, channel: String, attempts: Int, sequence: Int, rate: Double, status: AlertReservationStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.segment = segment
            self.channel = channel
            self.attempts = attempts
            self.sequence = sequence
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AlertReservationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == AlertReservationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedExposure() -> Double {
            return ((Double(attempts) - rate) * 100).rounded() / 100
        }

        func copyValue() -> AlertReservation {
            return AlertReservation(
                code: code,
                title: title,
                bed: bed,
                segment: segment,
                channel: channel,
                attempts: attempts,
                sequence: sequence,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a alert reservation in status draft.
    static func newAlertReservation(_ code: String, title: String) -> AlertReservation {
        return AlertReservation(
            code: code,
            title: title,
            bed: "",
            segment: "",
            channel: "",
            attempts: 0,
            sequence: 0,
            rate: 0.0,
            status: AlertReservationStatus.draft
        )
    }
}
