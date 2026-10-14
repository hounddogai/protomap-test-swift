import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task slot is in its life cycle.
    enum TaskSlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A task slot as the task team keeps it.
    final class TaskSlot {
        var code: String
        var name: String
        var endsAt: Int
        var attempts: Int
        var revision: Int
        var allergy: String
        var summary: String
        var capacity: Int
        var ownerID: String
        var dosageMg: Double
        var status: TaskSlotStatus

        init(code: String, name: String, endsAt: Int, attempts: Int, revision: Int, allergy: String, summary: String, capacity: Int, ownerID: String, dosageMg: Double, status: TaskSlotStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.attempts = attempts
            self.revision = revision
            self.allergy = allergy
            self.summary = summary
            self.capacity = capacity
            self.ownerID = ownerID
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: TaskSlotStatus) -> Bool {
            switch status {
            case .idle:
                return next == TaskSlotStatus.warming || next == TaskSlotStatus.stopped
            case .warming:
                return next == TaskSlotStatus.ready || next == TaskSlotStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == TaskSlotStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("task slot") \(code)"
        }

        func adjustedLoad() -> Double {
            return (Double(endsAt) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> TaskSlot {
            return TaskSlot(
                code: code,
                name: name,
                endsAt: endsAt,
                attempts: attempts,
                revision: revision,
                allergy: allergy,
                summary: summary,
                capacity: capacity,
                ownerID: ownerID,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a task slot in status idle.
    static func newTaskSlot(_ code: String, name: String) -> TaskSlot {
        return TaskSlot(
            code: code,
            name: name,
            endsAt: 0,
            attempts: 0,
            revision: 0,
            allergy: "",
            summary: "",
            capacity: 0,
            ownerID: "",
            dosageMg: 0.0,
            status: TaskSlotStatus.idle
        )
    }
}
