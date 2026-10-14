import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory adjustment is in its life cycle.
    enum InventoryAdjustmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A inventory adjustment. Its code is unique within a tenant.
    final class InventoryAdjustment {
        var code: String
        var label: String
        var currency: String
        var maximum: Double
        var ceiling: Double
        var payer: String
        var status: InventoryAdjustmentStatus

        init(code: String, label: String, currency: String, maximum: Double, ceiling: Double, payer: String, status: InventoryAdjustmentStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.maximum = maximum
            self.ceiling = ceiling
            self.payer = payer
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

        func canMoveTo(_ next: InventoryAdjustmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == InventoryAdjustmentStatus.done || next == InventoryAdjustmentStatus.failed
            case .running:
                return next == InventoryAdjustmentStatus.failed
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

        func moveTo(_ next: InventoryAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedValue() -> Double {
            return ((ceiling + maximum) * 100).rounded() / 100
        }

        func copyValue() -> InventoryAdjustment {
            return InventoryAdjustment(
                code: code,
                label: label,
                currency: currency,
                maximum: maximum,
                ceiling: ceiling,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a inventory adjustment in status new.
    static func newInventoryAdjustment(_ code: String, label: String) -> InventoryAdjustment {
        return InventoryAdjustment(
            code: code,
            label: label,
            currency: "",
            maximum: 0.0,
            ceiling: 0.0,
            payer: "",
            status: InventoryAdjustmentStatus.new
        )
    }
}
