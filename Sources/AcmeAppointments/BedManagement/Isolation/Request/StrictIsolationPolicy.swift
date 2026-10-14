import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict isolation policy is in its life cycle.
    enum StrictIsolationPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A strict isolation policy as the isolation team keeps it.
    final class StrictIsolationPolicy {
        var code: String
        var label: String
        var reviewer: String
        var capacity: Int
        var copay: Double
        var updatedAt: Int
        var budget: Double
        var weight: Double
        var score: Double
        var retries: Int
        var status: StrictIsolationPolicyStatus

        init(code: String, label: String, reviewer: String, capacity: Int, copay: Double, updatedAt: Int, budget: Double, weight: Double, score: Double, retries: Int, status: StrictIsolationPolicyStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.capacity = capacity
            self.copay = copay
            self.updatedAt = updatedAt
            self.budget = budget
            self.weight = weight
            self.score = score
            self.retries = retries
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

        func canMoveTo(_ next: StrictIsolationPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictIsolationPolicyStatus.approved || next == StrictIsolationPolicyStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == StrictIsolationPolicyStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictIsolationPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict isolation policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveValue() -> Double {
            return (Double(retries) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> StrictIsolationPolicy {
            return StrictIsolationPolicy(
                code: code,
                label: label,
                reviewer: reviewer,
                capacity: capacity,
                copay: copay,
                updatedAt: updatedAt,
                budget: budget,
                weight: weight,
                score: score,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict isolation policy in status proposed.
    static func newStrictIsolationPolicy(_ code: String, label: String) -> StrictIsolationPolicy {
        return StrictIsolationPolicy(
            code: code,
            label: label,
            reviewer: "",
            capacity: 0,
            copay: 0.0,
            updatedAt: 0,
            budget: 0.0,
            weight: 0.0,
            score: 0.0,
            retries: 0,
            status: StrictIsolationPolicyStatus.proposed
        )
    }
}
