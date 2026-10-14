import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched read plan is in its life cycle.
    enum BatchedReadPlanStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a batched read plan and its current status.
    final class BatchedReadPlan {
        var code: String
        var label: String
        var notes: String
        var name: String
        var country: String
        var ward: String
        var createdAt: Int
        var status: BatchedReadPlanStatus

        init(code: String, label: String, notes: String, name: String, country: String, ward: String, createdAt: Int, status: BatchedReadPlanStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.name = name
            self.country = country
            self.ward = ward
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedReadPlanStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == BatchedReadPlanStatus.inProgress || next == BatchedReadPlanStatus.cancelled
            case .inProgress:
                return next == BatchedReadPlanStatus.completed || next == BatchedReadPlanStatus.cancelled
            case .completed:
                return next == BatchedReadPlanStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedReadPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched read plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("batched read plan") \(code)"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> BatchedReadPlan {
            return BatchedReadPlan(
                code: code,
                label: label,
                notes: notes,
                name: name,
                country: country,
                ward: ward,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched read plan in status planned.
    static func newBatchedReadPlan(_ code: String, label: String) -> BatchedReadPlan {
        return BatchedReadPlan(
            code: code,
            label: label,
            notes: "",
            name: "",
            country: "",
            ward: "",
            createdAt: 0,
            status: BatchedReadPlanStatus.planned
        )
    }
}
