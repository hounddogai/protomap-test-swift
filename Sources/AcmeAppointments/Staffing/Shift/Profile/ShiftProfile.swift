import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift profile is in its life cycle.
    enum ShiftProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One shift profile, with what the planners need to act on it.
    final class ShiftProfile {
        var code: String
        var name: String
        var specialty: String
        var allergy: String
        var retries: Int
        var facility: String
        var attempts: Int
        var status: ShiftProfileStatus

        init(code: String, name: String, specialty: String, allergy: String, retries: Int, facility: String, attempts: Int, status: ShiftProfileStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.allergy = allergy
            self.retries = retries
            self.facility = facility
            self.attempts = attempts
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

        func canMoveTo(_ next: ShiftProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ShiftProfileStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ShiftProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedVolume() -> Double {
            return (Double(attempts) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> ShiftProfile {
            return ShiftProfile(
                code: code,
                name: name,
                specialty: specialty,
                allergy: allergy,
                retries: retries,
                facility: facility,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a shift profile in status draft.
    static func newShiftProfile(_ code: String, name: String) -> ShiftProfile {
        return ShiftProfile(
            code: code,
            name: name,
            specialty: "",
            allergy: "",
            retries: 0,
            facility: "",
            attempts: 0,
            status: ShiftProfileStatus.draft
        )
    }
}
