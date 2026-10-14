import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched denial policy is in its life cycle.
    enum BatchedDenialPolicyStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One batched denial policy, with what the planners need to act on it.
    final class BatchedDenialPolicy {
        var code: String
        var title: String
        var bed: String
        var active: Bool
        var capacity: Int
        var status: BatchedDenialPolicyStatus

        init(code: String, title: String, bed: String, active: Bool, capacity: Int, status: BatchedDenialPolicyStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.active = active
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedDenialPolicyStatus) -> Bool {
            switch status {
            case .idle:
                return next == BatchedDenialPolicyStatus.draining
            case .warming:
                return next == BatchedDenialPolicyStatus.ready || next == BatchedDenialPolicyStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == BatchedDenialPolicyStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedDenialPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched denial policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> BatchedDenialPolicy {
            return BatchedDenialPolicy(
                code: code,
                title: title,
                bed: bed,
                active: active,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched denial policy in status idle.
    static func newBatchedDenialPolicy(_ code: String, title: String) -> BatchedDenialPolicy {
        return BatchedDenialPolicy(
            code: code,
            title: title,
            bed: "",
            active: false,
            capacity: 0,
            status: BatchedDenialPolicyStatus.idle
        )
    }
}
