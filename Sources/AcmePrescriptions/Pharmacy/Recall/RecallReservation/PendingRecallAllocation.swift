import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending recall allocation is in its life cycle.
    enum PendingRecallAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One pending recall allocation, with what the planners need to act on it.
    final class PendingRecallAllocation {
        var code: String
        var name: String
        var quantity: Int
        var cost: Double
        var category: String
        var copay: Double
        var status: PendingRecallAllocationStatus

        init(code: String, name: String, quantity: Int, cost: Double, category: String, copay: Double, status: PendingRecallAllocationStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.cost = cost
            self.category = category
            self.copay = copay
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

        func canMoveTo(_ next: PendingRecallAllocationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
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
                return next == PendingRecallAllocationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingRecallAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending recall allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netExposure() -> Double {
            return (Double(quantity) * cost * 100).rounded() / 100
        }

        func copyValue() -> PendingRecallAllocation {
            return PendingRecallAllocation(
                code: code,
                name: name,
                quantity: quantity,
                cost: cost,
                category: category,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending recall allocation in status draft.
    static func newPendingRecallAllocation(_ code: String, name: String) -> PendingRecallAllocation {
        return PendingRecallAllocation(
            code: code,
            name: name,
            quantity: 0,
            cost: 0.0,
            category: "",
            copay: 0.0,
            status: PendingRecallAllocationStatus.draft
        )
    }
}
