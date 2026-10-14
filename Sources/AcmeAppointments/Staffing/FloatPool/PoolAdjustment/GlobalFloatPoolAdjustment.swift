import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global float pool adjustment is in its life cycle.
    enum GlobalFloatPoolAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A global float pool adjustment as the float pool team keeps it.
    final class GlobalFloatPoolAdjustment {
        var code: String
        var label: String
        var floorValue: Double
        var quantity: Int
        var minimum: Double
        var visitMinutes: Int
        var ownerID: String
        var attempts: Int
        var currency: String
        var retries: Int
        var rate: Double
        var status: GlobalFloatPoolAdjustmentStatus

        init(code: String, label: String, floorValue: Double, quantity: Int, minimum: Double, visitMinutes: Int, ownerID: String, attempts: Int, currency: String, retries: Int, rate: Double, status: GlobalFloatPoolAdjustmentStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.quantity = quantity
            self.minimum = minimum
            self.visitMinutes = visitMinutes
            self.ownerID = ownerID
            self.attempts = attempts
            self.currency = currency
            self.retries = retries
            self.rate = rate
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

        func canMoveTo(_ next: GlobalFloatPoolAdjustmentStatus) -> Bool {
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
                return next == GlobalFloatPoolAdjustmentStatus.suspended
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == GlobalFloatPoolAdjustmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalFloatPoolAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global float pool adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netExposure() -> Double {
            return ((Double(quantity) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalFloatPoolAdjustment {
            return GlobalFloatPoolAdjustment(
                code: code,
                label: label,
                floorValue: floorValue,
                quantity: quantity,
                minimum: minimum,
                visitMinutes: visitMinutes,
                ownerID: ownerID,
                attempts: attempts,
                currency: currency,
                retries: retries,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global float pool adjustment in status draft.
    static func newGlobalFloatPoolAdjustment(_ code: String, label: String) -> GlobalFloatPoolAdjustment {
        return GlobalFloatPoolAdjustment(
            code: code,
            label: label,
            floorValue: 0.0,
            quantity: 0,
            minimum: 0.0,
            visitMinutes: 0,
            ownerID: "",
            attempts: 0,
            currency: "",
            retries: 0,
            rate: 0.0,
            status: GlobalFloatPoolAdjustmentStatus.draft
        )
    }
}
