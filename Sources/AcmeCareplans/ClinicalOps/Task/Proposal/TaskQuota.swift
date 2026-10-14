import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task quota is in its life cycle.
    enum TaskQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A task quota as the task team keeps it.
    final class TaskQuota {
        var code: String
        var title: String
        var refills: Int
        var score: Double
        var threshold: Double
        var maximum: Double
        var notes: String
        var visitMinutes: Int
        var limit: Int
        var status: TaskQuotaStatus

        init(code: String, title: String, refills: Int, score: Double, threshold: Double, maximum: Double, notes: String, visitMinutes: Int, limit: Int, status: TaskQuotaStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.score = score
            self.threshold = threshold
            self.maximum = maximum
            self.notes = notes
            self.visitMinutes = visitMinutes
            self.limit = limit
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

        func canMoveTo(_ next: TaskQuotaStatus) -> Bool {
            switch status {
            case .created:
                return next == TaskQuotaStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: TaskQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedExposure() -> Double {
            return (maximum * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> TaskQuota {
            return TaskQuota(
                code: code,
                title: title,
                refills: refills,
                score: score,
                threshold: threshold,
                maximum: maximum,
                notes: notes,
                visitMinutes: visitMinutes,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a task quota in status created.
    static func newTaskQuota(_ code: String, title: String) -> TaskQuota {
        return TaskQuota(
            code: code,
            title: title,
            refills: 0,
            score: 0.0,
            threshold: 0.0,
            maximum: 0.0,
            notes: "",
            visitMinutes: 0,
            limit: 0,
            status: TaskQuotaStatus.created
        )
    }
}
