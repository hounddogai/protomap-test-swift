import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set budget is in its life cycle.
    enum OrderSetBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A order set budget. Its code is unique within a tenant.
    final class OrderSetBudget {
        var code: String
        var name: String
        var archived: Bool
        var ownerID: String
        var contactEmail: String
        var amount: Double
        var status: OrderSetBudgetStatus

        init(code: String, name: String, archived: Bool, ownerID: String, contactEmail: String, amount: Double, status: OrderSetBudgetStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.amount = amount
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

        func canMoveTo(_ next: OrderSetBudgetStatus) -> Bool {
            switch status {
            case .planned:
                return next == OrderSetBudgetStatus.completed || next == OrderSetBudgetStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: OrderSetBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("order set budget") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> OrderSetBudget {
            return OrderSetBudget(
                code: code,
                name: name,
                archived: archived,
                ownerID: ownerID,
                contactEmail: contactEmail,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a order set budget in status planned.
    static func newOrderSetBudget(_ code: String, name: String) -> OrderSetBudget {
        return OrderSetBudget(
            code: code,
            name: name,
            archived: false,
            ownerID: "",
            contactEmail: "",
            amount: 0.0,
            status: OrderSetBudgetStatus.planned
        )
    }
}
