import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task milestone is in its life cycle.
    enum TaskMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A task milestone as the task team keeps it.
    final class TaskMilestone {
        var code: String
        var title: String
        var approved: Bool
        var retries: Int
        var windowDays: Int
        var phone: String
        var batchSize: Int
        var threshold: Double
        var category: String
        var updatedAt: Int
        var status: TaskMilestoneStatus

        init(code: String, title: String, approved: Bool, retries: Int, windowDays: Int, phone: String, batchSize: Int, threshold: Double, category: String, updatedAt: Int, status: TaskMilestoneStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.retries = retries
            self.windowDays = windowDays
            self.phone = phone
            self.batchSize = batchSize
            self.threshold = threshold
            self.category = category
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TaskMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: TaskMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netLoad() -> Double {
            return (Double(windowDays) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> TaskMilestone {
            return TaskMilestone(
                code: code,
                title: title,
                approved: approved,
                retries: retries,
                windowDays: windowDays,
                phone: phone,
                batchSize: batchSize,
                threshold: threshold,
                category: category,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a task milestone in status draft.
    static func newTaskMilestone(_ code: String, title: String) -> TaskMilestone {
        return TaskMilestone(
            code: code,
            title: title,
            approved: false,
            retries: 0,
            windowDays: 0,
            phone: "",
            batchSize: 0,
            threshold: 0.0,
            category: "",
            updatedAt: 0,
            status: TaskMilestoneStatus.draft
        )
    }
}
