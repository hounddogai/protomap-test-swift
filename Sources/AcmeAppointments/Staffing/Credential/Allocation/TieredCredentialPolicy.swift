import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered credential policy is in its life cycle.
    enum TieredCredentialPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered credential policy as the credential team keeps it.
    final class TieredCredentialPolicy {
        var code: String
        var name: String
        var windowDays: Int
        var contactEmail: String
        var summary: String
        var maximum: Double
        var capacity: Int
        var clinicianID: String
        var description: String
        var reviewer: String
        var checksum: String
        var status: TieredCredentialPolicyStatus

        init(code: String, name: String, windowDays: Int, contactEmail: String, summary: String, maximum: Double, capacity: Int, clinicianID: String, description: String, reviewer: String, checksum: String, status: TieredCredentialPolicyStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.contactEmail = contactEmail
            self.summary = summary
            self.maximum = maximum
            self.capacity = capacity
            self.clinicianID = clinicianID
            self.description = description
            self.reviewer = reviewer
            self.checksum = checksum
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

        func canMoveTo(_ next: TieredCredentialPolicyStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredCredentialPolicyStatus.granted
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == TieredCredentialPolicyStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredCredentialPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered credential policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered credential policy") \(code)"
        }

        func projectedExposure() -> Double {
            return ((maximum + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> TieredCredentialPolicy {
            return TieredCredentialPolicy(
                code: code,
                name: name,
                windowDays: windowDays,
                contactEmail: contactEmail,
                summary: summary,
                maximum: maximum,
                capacity: capacity,
                clinicianID: clinicianID,
                description: description,
                reviewer: reviewer,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered credential policy in status requested.
    static func newTieredCredentialPolicy(_ code: String, name: String) -> TieredCredentialPolicy {
        return TieredCredentialPolicy(
            code: code,
            name: name,
            windowDays: 0,
            contactEmail: "",
            summary: "",
            maximum: 0.0,
            capacity: 0,
            clinicianID: "",
            description: "",
            reviewer: "",
            checksum: "",
            status: TieredCredentialPolicyStatus.requested
        )
    }
}
