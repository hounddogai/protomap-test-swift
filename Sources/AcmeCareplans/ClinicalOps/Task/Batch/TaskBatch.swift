import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task batch is in its life cycle.
    enum TaskBatchStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A task batch as the task team keeps it.
    final class TaskBatch {
        var code: String
        var name: String
        var attempts: Int
        var region: String
        var description: String
        var ratio: Double
        var createdAt: Int
        var minimum: Double
        var cost: Double
        var encounterID: String
        var status: TaskBatchStatus

        init(code: String, name: String, attempts: Int, region: String, description: String, ratio: Double, createdAt: Int, minimum: Double, cost: Double, encounterID: String, status: TaskBatchStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.region = region
            self.description = description
            self.ratio = ratio
            self.createdAt = createdAt
            self.minimum = minimum
            self.cost = cost
            self.encounterID = encounterID
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

        func canMoveTo(_ next: TaskBatchStatus) -> Bool {
            switch status {
            case .created:
                return next == TaskBatchStatus.published || next == TaskBatchStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == TaskBatchStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedTotal() -> Double {
            return ((Double(createdAt) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> TaskBatch {
            return TaskBatch(
                code: code,
                name: name,
                attempts: attempts,
                region: region,
                description: description,
                ratio: ratio,
                createdAt: createdAt,
                minimum: minimum,
                cost: cost,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a task batch in status created.
    static func newTaskBatch(_ code: String, name: String) -> TaskBatch {
        return TaskBatch(
            code: code,
            name: name,
            attempts: 0,
            region: "",
            description: "",
            ratio: 0.0,
            createdAt: 0,
            minimum: 0.0,
            cost: 0.0,
            encounterID: "",
            status: TaskBatchStatus.created
        )
    }
}
