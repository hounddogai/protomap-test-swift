import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending care protocol exception is in its life cycle.
    enum PendingCareProtocolExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One pending care protocol exception, with what the planners need to act on it.
    final class PendingCareProtocolException {
        var code: String
        var name: String
        var facility: String
        var description: String
        var startsAt: Int
        var contactEmail: String
        var status: PendingCareProtocolExceptionStatus

        init(code: String, name: String, facility: String, description: String, startsAt: Int, contactEmail: String, status: PendingCareProtocolExceptionStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.description = description
            self.startsAt = startsAt
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: PendingCareProtocolExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingCareProtocolExceptionStatus.approved || next == PendingCareProtocolExceptionStatus.rejected
            case .approved:
                switch next {
                case .rejected:
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

        func moveTo(_ next: PendingCareProtocolExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending care protocol exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> PendingCareProtocolException {
            return PendingCareProtocolException(
                code: code,
                name: name,
                facility: facility,
                description: description,
                startsAt: startsAt,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a pending care protocol exception in status proposed.
    static func newPendingCareProtocolException(_ code: String, name: String) -> PendingCareProtocolException {
        return PendingCareProtocolException(
            code: code,
            name: name,
            facility: "",
            description: "",
            startsAt: 0,
            contactEmail: "",
            status: PendingCareProtocolExceptionStatus.proposed
        )
    }
}
