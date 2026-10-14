import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional accession reservation is in its life cycle.
    enum RegionalAccessionReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One regional accession reservation, with what the planners need to act on it.
    final class RegionalAccessionReservation {
        var code: String
        var label: String
        var specialty: String
        var retries: Int
        var priority: Int
        var endsAt: Int
        var attempts: Int
        var sequence: Int
        var startsAt: Int
        var status: RegionalAccessionReservationStatus

        init(code: String, label: String, specialty: String, retries: Int, priority: Int, endsAt: Int, attempts: Int, sequence: Int, startsAt: Int, status: RegionalAccessionReservationStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.retries = retries
            self.priority = priority
            self.endsAt = endsAt
            self.attempts = attempts
            self.sequence = sequence
            self.startsAt = startsAt
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

        func canMoveTo(_ next: RegionalAccessionReservationStatus) -> Bool {
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
                return next == RegionalAccessionReservationStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RegionalAccessionReservationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAccessionReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional accession reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedLoad() -> Double {
            return (Double(retries) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> RegionalAccessionReservation {
            return RegionalAccessionReservation(
                code: code,
                label: label,
                specialty: specialty,
                retries: retries,
                priority: priority,
                endsAt: endsAt,
                attempts: attempts,
                sequence: sequence,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional accession reservation in status draft.
    static func newRegionalAccessionReservation(_ code: String, label: String) -> RegionalAccessionReservation {
        return RegionalAccessionReservation(
            code: code,
            label: label,
            specialty: "",
            retries: 0,
            priority: 0,
            endsAt: 0,
            attempts: 0,
            sequence: 0,
            startsAt: 0,
            status: RegionalAccessionReservationStatus.draft
        )
    }
}
