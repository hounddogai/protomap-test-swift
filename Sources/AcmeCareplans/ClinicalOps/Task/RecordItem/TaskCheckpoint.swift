import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task checkpoint is in its life cycle.
    enum TaskCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A task checkpoint. Its code is unique within a tenant.
    final class TaskCheckpoint {
        var code: String
        var label: String
        var pinned: Bool
        var cost: Double
        var channel: String
        var tags: [String]
        var copay: Double
        var quantity: Int
        var updatedAt: Int
        var startsAt: Int
        var status: TaskCheckpointStatus

        init(code: String, label: String, pinned: Bool, cost: Double, channel: String, tags: [String], copay: Double, quantity: Int, updatedAt: Int, startsAt: Int, status: TaskCheckpointStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.cost = cost
            self.channel = channel
            self.tags = tags
            self.copay = copay
            self.quantity = quantity
            self.updatedAt = updatedAt
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TaskCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TaskCheckpointStatus.archived
            case .inReview:
                return next == TaskCheckpointStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == TaskCheckpointStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedLoad() -> Double {
            return (copay * cost * 100).rounded() / 100
        }

        func copyValue() -> TaskCheckpoint {
            return TaskCheckpoint(
                code: code,
                label: label,
                pinned: pinned,
                cost: cost,
                channel: channel,
                tags: tags,
                copay: copay,
                quantity: quantity,
                updatedAt: updatedAt,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a task checkpoint in status open.
    static func newTaskCheckpoint(_ code: String, label: String) -> TaskCheckpoint {
        return TaskCheckpoint(
            code: code,
            label: label,
            pinned: false,
            cost: 0.0,
            channel: "",
            tags: [],
            copay: 0.0,
            quantity: 0,
            updatedAt: 0,
            startsAt: 0,
            status: TaskCheckpointStatus.`open`
        )
    }
}
