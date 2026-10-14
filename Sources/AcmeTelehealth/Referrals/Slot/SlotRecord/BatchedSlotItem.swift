import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched slot item is in its life cycle.
    enum BatchedSlotItemStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A batched slot item as the slot team keeps it.
    final class BatchedSlotItem {
        var code: String
        var label: String
        var procedureCode: String
        var region: String
        var pinned: Bool
        var amount: Double
        var status: BatchedSlotItemStatus

        init(code: String, label: String, procedureCode: String, region: String, pinned: Bool, amount: Double, status: BatchedSlotItemStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.region = region
            self.pinned = pinned
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

        func canMoveTo(_ next: BatchedSlotItemStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BatchedSlotItemStatus.running
            case .running:
                return next == BatchedSlotItemStatus.done || next == BatchedSlotItemStatus.failed
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

        func moveTo(_ next: BatchedSlotItemStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched slot item \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched slot item") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> BatchedSlotItem {
            return BatchedSlotItem(
                code: code,
                label: label,
                procedureCode: procedureCode,
                region: region,
                pinned: pinned,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a batched slot item in status new.
    static func newBatchedSlotItem(_ code: String, label: String) -> BatchedSlotItem {
        return BatchedSlotItem(
            code: code,
            label: label,
            procedureCode: "",
            region: "",
            pinned: false,
            amount: 0.0,
            status: BatchedSlotItemStatus.new
        )
    }
}
