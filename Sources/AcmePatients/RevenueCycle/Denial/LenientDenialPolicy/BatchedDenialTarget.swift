import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched denial target is in its life cycle.
    enum BatchedDenialTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a batched denial target and its current status.
    final class BatchedDenialTarget {
        var code: String
        var name: String
        var limit: Int
        var attempts: Int
        var ceiling: Double
        var graceDays: Int
        var contactEmail: String
        var status: BatchedDenialTargetStatus

        init(code: String, name: String, limit: Int, attempts: Int, ceiling: Double, graceDays: Int, contactEmail: String, status: BatchedDenialTargetStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.attempts = attempts
            self.ceiling = ceiling
            self.graceDays = graceDays
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: BatchedDenialTargetStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == BatchedDenialTargetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedDenialTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched denial target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched denial target") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(graceDays) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedDenialTarget {
            return BatchedDenialTarget(
                code: code,
                name: name,
                limit: limit,
                attempts: attempts,
                ceiling: ceiling,
                graceDays: graceDays,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched denial target in status idle.
    static func newBatchedDenialTarget(_ code: String, name: String) -> BatchedDenialTarget {
        return BatchedDenialTarget(
            code: code,
            name: name,
            limit: 0,
            attempts: 0,
            ceiling: 0.0,
            graceDays: 0,
            contactEmail: "",
            status: BatchedDenialTargetStatus.idle
        )
    }
}
