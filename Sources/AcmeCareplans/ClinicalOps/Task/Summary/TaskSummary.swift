import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task summary is in its life cycle.
    enum TaskSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a task summary and its current status.
    final class TaskSummary {
        var code: String
        var name: String
        var allergy: String
        var weight: Double
        var limit: Int
        var amount: Double
        var minimum: Double
        var status: TaskSummaryStatus

        init(code: String, name: String, allergy: String, weight: Double, limit: Int, amount: Double, minimum: Double, status: TaskSummaryStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.weight = weight
            self.limit = limit
            self.amount = amount
            self.minimum = minimum
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

        func canMoveTo(_ next: TaskSummaryStatus) -> Bool {
            switch status {
            case .idle:
                return next == TaskSummaryStatus.draining || next == TaskSummaryStatus.stopped
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == TaskSummaryStatus.draining || next == TaskSummaryStatus.stopped
            case .draining:
                return next == TaskSummaryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return (minimum * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> TaskSummary {
            return TaskSummary(
                code: code,
                name: name,
                allergy: allergy,
                weight: weight,
                limit: limit,
                amount: amount,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a task summary in status idle.
    static func newTaskSummary(_ code: String, name: String) -> TaskSummary {
        return TaskSummary(
            code: code,
            name: name,
            allergy: "",
            weight: 0.0,
            limit: 0,
            amount: 0.0,
            minimum: 0.0,
            status: TaskSummaryStatus.idle
        )
    }
}
