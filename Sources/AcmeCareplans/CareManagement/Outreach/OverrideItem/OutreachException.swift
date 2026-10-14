import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach exception is in its life cycle.
    enum OutreachExceptionStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A outreach exception as the outreach team keeps it.
    final class OutreachException {
        var code: String
        var title: String
        var archived: Bool
        var contactEmail: String
        var createdAt: Int
        var active: Bool
        var status: OutreachExceptionStatus

        init(code: String, title: String, archived: Bool, contactEmail: String, createdAt: Int, active: Bool, status: OutreachExceptionStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.contactEmail = contactEmail
            self.createdAt = createdAt
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OutreachExceptionStatus) -> Bool {
            switch status {
            case .requested:
                return next == OutreachExceptionStatus.granted
            case .granted:
                return next == OutreachExceptionStatus.revoked || next == OutreachExceptionStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: OutreachExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("outreach exception") \(code)"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> OutreachException {
            return OutreachException(
                code: code,
                title: title,
                archived: archived,
                contactEmail: contactEmail,
                createdAt: createdAt,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a outreach exception in status requested.
    static func newOutreachException(_ code: String, title: String) -> OutreachException {
        return OutreachException(
            code: code,
            title: title,
            archived: false,
            contactEmail: "",
            createdAt: 0,
            active: false,
            status: OutreachExceptionStatus.requested
        )
    }
}
