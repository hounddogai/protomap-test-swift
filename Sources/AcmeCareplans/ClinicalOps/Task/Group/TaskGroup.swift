import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task group is in its life cycle.
    enum TaskGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A task group as the task team keeps it.
    final class TaskGroup {
        var code: String
        var title: String
        var payer: String
        var clinicianID: String
        var graceDays: Int
        var limit: Int
        var status: TaskGroupStatus

        init(code: String, title: String, payer: String, clinicianID: String, graceDays: Int, limit: Int, status: TaskGroupStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.clinicianID = clinicianID
            self.graceDays = graceDays
            self.limit = limit
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

        func canMoveTo(_ next: TaskGroupStatus) -> Bool {
            switch status {
            case .new:
                return next == TaskGroupStatus.done
            case .queued:
                return next == TaskGroupStatus.running || next == TaskGroupStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == TaskGroupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netVolume() -> Double {
            return ((Double(graceDays) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> TaskGroup {
            return TaskGroup(
                code: code,
                title: title,
                payer: payer,
                clinicianID: clinicianID,
                graceDays: graceDays,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a task group in status new.
    static func newTaskGroup(_ code: String, title: String) -> TaskGroup {
        return TaskGroup(
            code: code,
            title: title,
            payer: "",
            clinicianID: "",
            graceDays: 0,
            limit: 0,
            status: TaskGroupStatus.new
        )
    }
}
