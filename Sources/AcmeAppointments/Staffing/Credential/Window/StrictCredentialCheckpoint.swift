import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict credential checkpoint is in its life cycle.
    enum StrictCredentialCheckpointStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One strict credential checkpoint, with what the planners need to act on it.
    final class StrictCredentialCheckpoint {
        var code: String
        var name: String
        var contactEmail: String
        var quantity: Int
        var timezone: String
        var ward: String
        var approved: Bool
        var status: StrictCredentialCheckpointStatus

        init(code: String, name: String, contactEmail: String, quantity: Int, timezone: String, ward: String, approved: Bool, status: StrictCredentialCheckpointStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.quantity = quantity
            self.timezone = timezone
            self.ward = ward
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictCredentialCheckpointStatus) -> Bool {
            switch status {
            case .created:
                return next == StrictCredentialCheckpointStatus.published || next == StrictCredentialCheckpointStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == StrictCredentialCheckpointStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictCredentialCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict credential checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict credential checkpoint") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> StrictCredentialCheckpoint {
            return StrictCredentialCheckpoint(
                code: code,
                name: name,
                contactEmail: contactEmail,
                quantity: quantity,
                timezone: timezone,
                ward: ward,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a strict credential checkpoint in status created.
    static func newStrictCredentialCheckpoint(_ code: String, name: String) -> StrictCredentialCheckpoint {
        return StrictCredentialCheckpoint(
            code: code,
            name: name,
            contactEmail: "",
            quantity: 0,
            timezone: "",
            ward: "",
            approved: false,
            status: StrictCredentialCheckpointStatus.created
        )
    }
}
