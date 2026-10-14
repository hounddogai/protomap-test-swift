import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task digest is in its life cycle.
    enum TaskDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One task digest, with what the planners need to act on it.
    final class TaskDigest {
        var code: String
        var title: String
        var active: Bool
        var amount: Double
        var ceiling: Double
        var priority: Int
        var status: TaskDigestStatus

        init(code: String, title: String, active: Bool, amount: Double, ceiling: Double, priority: Int, status: TaskDigestStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.amount = amount
            self.ceiling = ceiling
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TaskDigestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == TaskDigestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("task digest") \(code)"
        }

        func effectiveValue() -> Double {
            return (amount * ceiling * 100).rounded() / 100
        }

        func copyValue() -> TaskDigest {
            return TaskDigest(
                code: code,
                title: title,
                active: active,
                amount: amount,
                ceiling: ceiling,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a task digest in status created.
    static func newTaskDigest(_ code: String, title: String) -> TaskDigest {
        return TaskDigest(
            code: code,
            title: title,
            active: false,
            amount: 0.0,
            ceiling: 0.0,
            priority: 0,
            status: TaskDigestStatus.created
        )
    }
}
