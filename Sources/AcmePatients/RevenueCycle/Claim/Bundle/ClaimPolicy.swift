import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim policy is in its life cycle.
    enum ClaimPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A claim policy as the claim team keeps it.
    final class ClaimPolicy {
        var code: String
        var name: String
        var timezone: String
        var attributes: [String: String]
        var revision: Int
        var amount: Double
        var pinned: Bool
        var copay: Double
        var limit: Int
        var visitMinutes: Int
        var status: ClaimPolicyStatus

        init(code: String, name: String, timezone: String, attributes: [String: String], revision: Int, amount: Double, pinned: Bool, copay: Double, limit: Int, visitMinutes: Int, status: ClaimPolicyStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.attributes = attributes
            self.revision = revision
            self.amount = amount
            self.pinned = pinned
            self.copay = copay
            self.limit = limit
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: ClaimPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ClaimPolicyStatus.resolved || next == ClaimPolicyStatus.reopened
            case .resolved:
                return next == ClaimPolicyStatus.reopened || next == ClaimPolicyStatus.archived
            case .reopened:
                return next == ClaimPolicyStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
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

        func weightedVolume() -> Double {
            return (Double(limit) * copay * 100).rounded() / 100
        }

        func copyValue() -> ClaimPolicy {
            return ClaimPolicy(
                code: code,
                name: name,
                timezone: timezone,
                attributes: attributes,
                revision: revision,
                amount: amount,
                pinned: pinned,
                copay: copay,
                limit: limit,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a claim policy in status open.
    static func newClaimPolicy(_ code: String, name: String) -> ClaimPolicy {
        return ClaimPolicy(
            code: code,
            name: name,
            timezone: "",
            attributes: [:],
            revision: 0,
            amount: 0.0,
            pinned: false,
            copay: 0.0,
            limit: 0,
            visitMinutes: 0,
            status: ClaimPolicyStatus.`open`
        )
    }
}
