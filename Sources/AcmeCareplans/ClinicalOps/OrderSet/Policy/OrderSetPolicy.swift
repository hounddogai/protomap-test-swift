import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set policy is in its life cycle.
    enum OrderSetPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a order set policy and its current status.
    final class OrderSetPolicy {
        var code: String
        var label: String
        var amount: Double
        var retries: Int
        var name: String
        var archived: Bool
        var status: OrderSetPolicyStatus

        init(code: String, label: String, amount: Double, retries: Int, name: String, archived: Bool, status: OrderSetPolicyStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.retries = retries
            self.name = name
            self.archived = archived
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

        func canMoveTo(_ next: OrderSetPolicyStatus) -> Bool {
            switch status {
            case .draft:
                return next == OrderSetPolicyStatus.pending || next == OrderSetPolicyStatus.active
            case .pending:
                return next == OrderSetPolicyStatus.suspended || next == OrderSetPolicyStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == OrderSetPolicyStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveLoad() -> Double {
            return ((Double(retries) + amount) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetPolicy {
            return OrderSetPolicy(
                code: code,
                label: label,
                amount: amount,
                retries: retries,
                name: name,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a order set policy in status draft.
    static func newOrderSetPolicy(_ code: String, label: String) -> OrderSetPolicy {
        return OrderSetPolicy(
            code: code,
            label: label,
            amount: 0.0,
            retries: 0,
            name: "",
            archived: false,
            status: OrderSetPolicyStatus.draft
        )
    }
}
