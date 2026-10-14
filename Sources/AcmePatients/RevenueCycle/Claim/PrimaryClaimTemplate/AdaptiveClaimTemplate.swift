import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive claim template is in its life cycle.
    enum AdaptiveClaimTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive claim template. Its code is unique within a tenant.
    final class AdaptiveClaimTemplate {
        var code: String
        var name: String
        var contactEmail: String
        var specialty: String
        var ownerID: String
        var attempts: Int
        var capacity: Int
        var status: AdaptiveClaimTemplateStatus

        init(code: String, name: String, contactEmail: String, specialty: String, ownerID: String, attempts: Int, capacity: Int, status: AdaptiveClaimTemplateStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.specialty = specialty
            self.ownerID = ownerID
            self.attempts = attempts
            self.capacity = capacity
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

        func canMoveTo(_ next: AdaptiveClaimTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveClaimTemplateStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AdaptiveClaimTemplateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveClaimTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive claim template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive claim template") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(capacity) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveClaimTemplate {
            return AdaptiveClaimTemplate(
                code: code,
                name: name,
                contactEmail: contactEmail,
                specialty: specialty,
                ownerID: ownerID,
                attempts: attempts,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive claim template in status proposed.
    static func newAdaptiveClaimTemplate(_ code: String, name: String) -> AdaptiveClaimTemplate {
        return AdaptiveClaimTemplate(
            code: code,
            name: name,
            contactEmail: "",
            specialty: "",
            ownerID: "",
            attempts: 0,
            capacity: 0,
            status: AdaptiveClaimTemplateStatus.proposed
        )
    }
}
