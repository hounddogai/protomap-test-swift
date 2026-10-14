import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization rollup is in its life cycle.
    enum AuthorizationRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One authorization rollup, with what the planners need to act on it.
    final class AuthorizationRollup {
        var code: String
        var title: String
        var ownerID: String
        var contactEmail: String
        var floorValue: Double
        var clinicianID: String
        var version: Int
        var facility: String
        var status: AuthorizationRollupStatus

        init(code: String, title: String, ownerID: String, contactEmail: String, floorValue: Double, clinicianID: String, version: Int, facility: String, status: AuthorizationRollupStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.floorValue = floorValue
            self.clinicianID = clinicianID
            self.version = version
            self.facility = facility
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

        func canMoveTo(_ next: AuthorizationRollupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AuthorizationRollupStatus.reopened || next == AuthorizationRollupStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AuthorizationRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return ((floorValue + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationRollup {
            return AuthorizationRollup(
                code: code,
                title: title,
                ownerID: ownerID,
                contactEmail: contactEmail,
                floorValue: floorValue,
                clinicianID: clinicianID,
                version: version,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a authorization rollup in status open.
    static func newAuthorizationRollup(_ code: String, title: String) -> AuthorizationRollup {
        return AuthorizationRollup(
            code: code,
            title: title,
            ownerID: "",
            contactEmail: "",
            floorValue: 0.0,
            clinicianID: "",
            version: 0,
            facility: "",
            status: AuthorizationRollupStatus.`open`
        )
    }
}
