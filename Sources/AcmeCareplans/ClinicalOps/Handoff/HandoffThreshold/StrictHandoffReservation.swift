import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict handoff reservation is in its life cycle.
    enum StrictHandoffReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A strict handoff reservation as the handoff team keeps it.
    final class StrictHandoffReservation {
        var code: String
        var label: String
        var name: String
        var country: String
        var notes: String
        var capacity: Int
        var status: StrictHandoffReservationStatus

        init(code: String, label: String, name: String, country: String, notes: String, capacity: Int, status: StrictHandoffReservationStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.country = country
            self.notes = notes
            self.capacity = capacity
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

        func canMoveTo(_ next: StrictHandoffReservationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == StrictHandoffReservationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictHandoffReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict handoff reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> StrictHandoffReservation {
            return StrictHandoffReservation(
                code: code,
                label: label,
                name: name,
                country: country,
                notes: notes,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a strict handoff reservation in status open.
    static func newStrictHandoffReservation(_ code: String, label: String) -> StrictHandoffReservation {
        return StrictHandoffReservation(
            code: code,
            label: label,
            name: "",
            country: "",
            notes: "",
            capacity: 0,
            status: StrictHandoffReservationStatus.`open`
        )
    }
}
