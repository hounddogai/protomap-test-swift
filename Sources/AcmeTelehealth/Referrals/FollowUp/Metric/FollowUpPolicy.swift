import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up policy is in its life cycle.
    enum FollowUpPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A follow up policy. Its code is unique within a tenant.
    final class FollowUpPolicy {
        var code: String
        var label: String
        var rate: Double
        var phone: String
        var threshold: Double
        var updatedAt: Int
        var revision: Int
        var capacity: Int
        var attributes: [String: String]
        var status: FollowUpPolicyStatus

        init(code: String, label: String, rate: Double, phone: String, threshold: Double, updatedAt: Int, revision: Int, capacity: Int, attributes: [String: String], status: FollowUpPolicyStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.phone = phone
            self.threshold = threshold
            self.updatedAt = updatedAt
            self.revision = revision
            self.capacity = capacity
            self.attributes = attributes
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

        func canMoveTo(_ next: FollowUpPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FollowUpPolicyStatus.rejected || next == FollowUpPolicyStatus.withdrawn
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

        func moveTo(_ next: FollowUpPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netValue() -> Double {
            return ((Double(capacity) - rate) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpPolicy {
            return FollowUpPolicy(
                code: code,
                label: label,
                rate: rate,
                phone: phone,
                threshold: threshold,
                updatedAt: updatedAt,
                revision: revision,
                capacity: capacity,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a follow up policy in status proposed.
    static func newFollowUpPolicy(_ code: String, label: String) -> FollowUpPolicy {
        return FollowUpPolicy(
            code: code,
            label: label,
            rate: 0.0,
            phone: "",
            threshold: 0.0,
            updatedAt: 0,
            revision: 0,
            capacity: 0,
            attributes: [:],
            status: FollowUpPolicyStatus.proposed
        )
    }
}
