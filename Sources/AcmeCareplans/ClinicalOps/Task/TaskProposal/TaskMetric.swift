import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task metric is in its life cycle.
    enum TaskMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A task metric as the task team keeps it.
    final class TaskMetric {
        var code: String
        var title: String
        var minimum: Double
        var retries: Int
        var amount: Double
        var sequence: Int
        var locale: String
        var revision: Int
        var version: Int
        var margin: Double
        var status: TaskMetricStatus

        init(code: String, title: String, minimum: Double, retries: Int, amount: Double, sequence: Int, locale: String, revision: Int, version: Int, margin: Double, status: TaskMetricStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.retries = retries
            self.amount = amount
            self.sequence = sequence
            self.locale = locale
            self.revision = revision
            self.version = version
            self.margin = margin
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

        func canMoveTo(_ next: TaskMetricStatus) -> Bool {
            switch status {
            case .idle:
                return next == TaskMetricStatus.warming
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == TaskMetricStatus.draining || next == TaskMetricStatus.stopped
            case .draining:
                return next == TaskMetricStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveLoad() -> Double {
            return (Double(version) * minimum * 100).rounded() / 100
        }

        func copyValue() -> TaskMetric {
            return TaskMetric(
                code: code,
                title: title,
                minimum: minimum,
                retries: retries,
                amount: amount,
                sequence: sequence,
                locale: locale,
                revision: revision,
                version: version,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a task metric in status idle.
    static func newTaskMetric(_ code: String, title: String) -> TaskMetric {
        return TaskMetric(
            code: code,
            title: title,
            minimum: 0.0,
            retries: 0,
            amount: 0.0,
            sequence: 0,
            locale: "",
            revision: 0,
            version: 0,
            margin: 0.0,
            status: TaskMetricStatus.idle
        )
    }
}
