import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default care protocol exception is in its life cycle.
    enum DefaultCareProtocolExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default care protocol exception as the care protocol team keeps it.
    final class DefaultCareProtocolException {
        var code: String
        var title: String
        var windowDays: Int
        var contactEmail: String
        var encounterID: String
        var ownerID: String
        var endsAt: Int
        var category: String
        var pinned: Bool
        var status: DefaultCareProtocolExceptionStatus

        init(code: String, title: String, windowDays: Int, contactEmail: String, encounterID: String, ownerID: String, endsAt: Int, category: String, pinned: Bool, status: DefaultCareProtocolExceptionStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.contactEmail = contactEmail
            self.encounterID = encounterID
            self.ownerID = ownerID
            self.endsAt = endsAt
            self.category = category
            self.pinned = pinned
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

        func canMoveTo(_ next: DefaultCareProtocolExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultCareProtocolExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default care protocol exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netExposure() -> Double {
            return ((Double(endsAt) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCareProtocolException {
            return DefaultCareProtocolException(
                code: code,
                title: title,
                windowDays: windowDays,
                contactEmail: contactEmail,
                encounterID: encounterID,
                ownerID: ownerID,
                endsAt: endsAt,
                category: category,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a default care protocol exception in status proposed.
    static func newDefaultCareProtocolException(_ code: String, title: String) -> DefaultCareProtocolException {
        return DefaultCareProtocolException(
            code: code,
            title: title,
            windowDays: 0,
            contactEmail: "",
            encounterID: "",
            ownerID: "",
            endsAt: 0,
            category: "",
            pinned: false,
            status: DefaultCareProtocolExceptionStatus.proposed
        )
    }
}
