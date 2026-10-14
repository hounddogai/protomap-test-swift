import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched remittance allocation is in its life cycle.
    enum BatchedRemittanceAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a batched remittance allocation and its current status.
    final class BatchedRemittanceAllocation {
        var code: String
        var label: String
        var category: String
        var payer: String
        var visible: Bool
        var amount: Double
        var status: BatchedRemittanceAllocationStatus

        init(code: String, label: String, category: String, payer: String, visible: Bool, amount: Double, status: BatchedRemittanceAllocationStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.payer = payer
            self.visible = visible
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedRemittanceAllocationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == BatchedRemittanceAllocationStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: BatchedRemittanceAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched remittance allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> BatchedRemittanceAllocation {
            return BatchedRemittanceAllocation(
                code: code,
                label: label,
                category: category,
                payer: payer,
                visible: visible,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched remittance allocation in status new.
    static func newBatchedRemittanceAllocation(_ code: String, label: String) -> BatchedRemittanceAllocation {
        return BatchedRemittanceAllocation(
            code: code,
            label: label,
            category: "",
            payer: "",
            visible: false,
            amount: 0.0,
            status: BatchedRemittanceAllocationStatus.new
        )
    }
}
