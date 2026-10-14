import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched risk score override is in its life cycle.
    enum BatchedRiskScoreOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One batched risk score override, with what the planners need to act on it.
    final class BatchedRiskScoreOverride {
        var code: String
        var label: String
        var limit: Int
        var priority: Int
        var capacity: Int
        var status: BatchedRiskScoreOverrideStatus

        init(code: String, label: String, limit: Int, priority: Int, capacity: Int, status: BatchedRiskScoreOverrideStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.priority = priority
            self.capacity = capacity
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

        func canMoveTo(_ next: BatchedRiskScoreOverrideStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: BatchedRiskScoreOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched risk score override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedTotal() -> Double {
            return (Double(limit) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> BatchedRiskScoreOverride {
            return BatchedRiskScoreOverride(
                code: code,
                label: label,
                limit: limit,
                priority: priority,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched risk score override in status requested.
    static func newBatchedRiskScoreOverride(_ code: String, label: String) -> BatchedRiskScoreOverride {
        return BatchedRiskScoreOverride(
            code: code,
            label: label,
            limit: 0,
            priority: 0,
            capacity: 0,
            status: BatchedRiskScoreOverrideStatus.requested
        )
    }
}
