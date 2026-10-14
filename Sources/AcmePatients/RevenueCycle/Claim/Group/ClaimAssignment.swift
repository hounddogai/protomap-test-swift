import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim assignment is in its life cycle.
    enum ClaimAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a claim assignment and its current status.
    final class ClaimAssignment {
        var code: String
        var title: String
        var phone: String
        var segment: String
        var contactEmail: String
        var amount: Double
        var status: ClaimAssignmentStatus

        init(code: String, title: String, phone: String, segment: String, contactEmail: String, amount: Double, status: ClaimAssignmentStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.segment = segment
            self.contactEmail = contactEmail
            self.amount = amount
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

        func canMoveTo(_ next: ClaimAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == ClaimAssignmentStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ClaimAssignmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("claim assignment") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> ClaimAssignment {
            return ClaimAssignment(
                code: code,
                title: title,
                phone: phone,
                segment: segment,
                contactEmail: contactEmail,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a claim assignment in status requested.
    static func newClaimAssignment(_ code: String, title: String) -> ClaimAssignment {
        return ClaimAssignment(
            code: code,
            title: title,
            phone: "",
            segment: "",
            contactEmail: "",
            amount: 0.0,
            status: ClaimAssignmentStatus.requested
        )
    }
}
