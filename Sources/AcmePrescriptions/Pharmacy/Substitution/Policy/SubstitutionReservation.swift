import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution reservation is in its life cycle.
    enum SubstitutionReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A substitution reservation. Its code is unique within a tenant.
    final class SubstitutionReservation {
        var code: String
        var title: String
        var retries: Int
        var name: String
        var refills: Int
        var windowDays: Int
        var active: Bool
        var allergy: String
        var status: SubstitutionReservationStatus

        init(code: String, title: String, retries: Int, name: String, refills: Int, windowDays: Int, active: Bool, allergy: String, status: SubstitutionReservationStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.name = name
            self.refills = refills
            self.windowDays = windowDays
            self.active = active
            self.allergy = allergy
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

        func canMoveTo(_ next: SubstitutionReservationStatus) -> Bool {
            switch status {
            case .draft:
                return next == SubstitutionReservationStatus.pending
            case .pending:
                return next == SubstitutionReservationStatus.active || next == SubstitutionReservationStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == SubstitutionReservationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("substitution reservation") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(refills) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionReservation {
            return SubstitutionReservation(
                code: code,
                title: title,
                retries: retries,
                name: name,
                refills: refills,
                windowDays: windowDays,
                active: active,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a substitution reservation in status draft.
    static func newSubstitutionReservation(_ code: String, title: String) -> SubstitutionReservation {
        return SubstitutionReservation(
            code: code,
            title: title,
            retries: 0,
            name: "",
            refills: 0,
            windowDays: 0,
            active: false,
            allergy: "",
            status: SubstitutionReservationStatus.draft
        )
    }
}
