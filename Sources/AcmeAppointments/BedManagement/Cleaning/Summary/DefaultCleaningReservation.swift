import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default cleaning reservation is in its life cycle.
    enum DefaultCleaningReservationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One default cleaning reservation, with what the planners need to act on it.
    final class DefaultCleaningReservation {
        var code: String
        var label: String
        var cost: Double
        var endsAt: Int
        var channel: String
        var ceiling: Double
        var sequence: Int
        var status: DefaultCleaningReservationStatus

        init(code: String, label: String, cost: Double, endsAt: Int, channel: String, ceiling: Double, sequence: Int, status: DefaultCleaningReservationStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.endsAt = endsAt
            self.channel = channel
            self.ceiling = ceiling
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultCleaningReservationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DefaultCleaningReservationStatus.ready || next == DefaultCleaningReservationStatus.stopped
            case .ready:
                return next == DefaultCleaningReservationStatus.stopped
            case .draining:
                return next == DefaultCleaningReservationStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCleaningReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default cleaning reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveExposure() -> Double {
            return (ceiling * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCleaningReservation {
            return DefaultCleaningReservation(
                code: code,
                label: label,
                cost: cost,
                endsAt: endsAt,
                channel: channel,
                ceiling: ceiling,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a default cleaning reservation in status idle.
    static func newDefaultCleaningReservation(_ code: String, label: String) -> DefaultCleaningReservation {
        return DefaultCleaningReservation(
            code: code,
            label: label,
            cost: 0.0,
            endsAt: 0,
            channel: "",
            ceiling: 0.0,
            sequence: 0,
            status: DefaultCleaningReservationStatus.idle
        )
    }
}
