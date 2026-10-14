import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program exception is in its life cycle.
    enum ProgramExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One program exception, with what the planners need to act on it.
    final class ProgramException {
        var code: String
        var name: String
        var currency: String
        var pinned: Bool
        var endsAt: Int
        var retries: Int
        var phone: String
        var country: String
        var archived: Bool
        var durationMinutes: Int
        var status: ProgramExceptionStatus

        init(code: String, name: String, currency: String, pinned: Bool, endsAt: Int, retries: Int, phone: String, country: String, archived: Bool, durationMinutes: Int, status: ProgramExceptionStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.pinned = pinned
            self.endsAt = endsAt
            self.retries = retries
            self.phone = phone
            self.country = country
            self.archived = archived
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProgramExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ProgramExceptionStatus.rejected || next == ProgramExceptionStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ProgramExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedExposure() -> Double {
            return ((Double(endsAt) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ProgramException {
            return ProgramException(
                code: code,
                name: name,
                currency: currency,
                pinned: pinned,
                endsAt: endsAt,
                retries: retries,
                phone: phone,
                country: country,
                archived: archived,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a program exception in status proposed.
    static func newProgramException(_ code: String, name: String) -> ProgramException {
        return ProgramException(
            code: code,
            name: name,
            currency: "",
            pinned: false,
            endsAt: 0,
            retries: 0,
            phone: "",
            country: "",
            archived: false,
            durationMinutes: 0,
            status: ProgramExceptionStatus.proposed
        )
    }
}
