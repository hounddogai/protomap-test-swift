import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task policy is in its life cycle.
    enum TaskPolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A task policy as the task team keeps it.
    final class TaskPolicy {
        var code: String
        var title: String
        var endsAt: Int
        var category: String
        var margin: Double
        var retries: Int
        var status: TaskPolicyStatus

        init(code: String, title: String, endsAt: Int, category: String, margin: Double, retries: Int, status: TaskPolicyStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.category = category
            self.margin = margin
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TaskPolicyStatus) -> Bool {
            switch status {
            case .new:
                return next == TaskPolicyStatus.queued || next == TaskPolicyStatus.failed
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == TaskPolicyStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netLoad() -> Double {
            return (Double(endsAt) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> TaskPolicy {
            return TaskPolicy(
                code: code,
                title: title,
                endsAt: endsAt,
                category: category,
                margin: margin,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a task policy in status new.
    static func newTaskPolicy(_ code: String, title: String) -> TaskPolicy {
        return TaskPolicy(
            code: code,
            title: title,
            endsAt: 0,
            category: "",
            margin: 0.0,
            retries: 0,
            status: TaskPolicyStatus.new
        )
    }
}
