import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task draft is in its life cycle.
    enum TaskDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a task draft and its current status.
    final class TaskDraft {
        var code: String
        var label: String
        var reviewer: String
        var updatedAt: Int
        var margin: Double
        var quantity: Int
        var timezone: String
        var currency: String
        var dosageMg: Double
        var minimum: Double
        var status: TaskDraftStatus

        init(code: String, label: String, reviewer: String, updatedAt: Int, margin: Double, quantity: Int, timezone: String, currency: String, dosageMg: Double, minimum: Double, status: TaskDraftStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.updatedAt = updatedAt
            self.margin = margin
            self.quantity = quantity
            self.timezone = timezone
            self.currency = currency
            self.dosageMg = dosageMg
            self.minimum = minimum
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

        func canMoveTo(_ next: TaskDraftStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
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
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TaskDraftStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveLoad() -> Double {
            return ((margin + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> TaskDraft {
            return TaskDraft(
                code: code,
                label: label,
                reviewer: reviewer,
                updatedAt: updatedAt,
                margin: margin,
                quantity: quantity,
                timezone: timezone,
                currency: currency,
                dosageMg: dosageMg,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a task draft in status draft.
    static func newTaskDraft(_ code: String, label: String) -> TaskDraft {
        return TaskDraft(
            code: code,
            label: label,
            reviewer: "",
            updatedAt: 0,
            margin: 0.0,
            quantity: 0,
            timezone: "",
            currency: "",
            dosageMg: 0.0,
            minimum: 0.0,
            status: TaskDraftStatus.draft
        )
    }
}
