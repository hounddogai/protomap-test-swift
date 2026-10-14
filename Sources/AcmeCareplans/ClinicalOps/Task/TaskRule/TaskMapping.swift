import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task mapping is in its life cycle.
    enum TaskMappingStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One task mapping, with what the planners need to act on it.
    final class TaskMapping {
        var code: String
        var title: String
        var visitMinutes: Int
        var score: Double
        var locale: String
        var refills: Int
        var priority: Int
        var notes: String
        var status: TaskMappingStatus

        init(code: String, title: String, visitMinutes: Int, score: Double, locale: String, refills: Int, priority: Int, notes: String, status: TaskMappingStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.score = score
            self.locale = locale
            self.refills = refills
            self.priority = priority
            self.notes = notes
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

        func canMoveTo(_ next: TaskMappingStatus) -> Bool {
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
                case .published:
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

        func moveTo(_ next: TaskMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("task mapping") \(code)"
        }

        func projectedLoad() -> Double {
            return (score * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> TaskMapping {
            return TaskMapping(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                score: score,
                locale: locale,
                refills: refills,
                priority: priority,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a task mapping in status created.
    static func newTaskMapping(_ code: String, title: String) -> TaskMapping {
        return TaskMapping(
            code: code,
            title: title,
            visitMinutes: 0,
            score: 0.0,
            locale: "",
            refills: 0,
            priority: 0,
            notes: "",
            status: TaskMappingStatus.created
        )
    }
}
