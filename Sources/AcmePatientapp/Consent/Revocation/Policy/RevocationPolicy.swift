import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation policy is in its life cycle.
    enum RevocationPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One revocation policy, with what the planners need to act on it.
    final class RevocationPolicy {
        var code: String
        var label: String
        var specialty: String
        var segment: String
        var discount: Double
        var region: String
        var status: RevocationPolicyStatus

        init(code: String, label: String, specialty: String, segment: String, discount: Double, region: String, status: RevocationPolicyStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.segment = segment
            self.discount = discount
            self.region = region
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

        func canMoveTo(_ next: RevocationPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RevocationPolicyStatus.resolved
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RevocationPolicyStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("revocation policy") \(code)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> RevocationPolicy {
            return RevocationPolicy(
                code: code,
                label: label,
                specialty: specialty,
                segment: segment,
                discount: discount,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a revocation policy in status open.
    static func newRevocationPolicy(_ code: String, label: String) -> RevocationPolicy {
        return RevocationPolicy(
            code: code,
            label: label,
            specialty: "",
            segment: "",
            discount: 0.0,
            region: "",
            status: RevocationPolicyStatus.`open`
        )
    }
}
