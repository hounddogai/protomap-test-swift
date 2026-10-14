import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback order set batch is in its life cycle.
    enum FallbackOrderSetBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback order set batch as the order set team keeps it.
    final class FallbackOrderSetBatch {
        var code: String
        var label: String
        var cost: Double
        var allergy: String
        var windowDays: Int
        var name: String
        var amount: Double
        var acuity: Int
        var durationMinutes: Int
        var quantity: Int
        var status: FallbackOrderSetBatchStatus

        init(code: String, label: String, cost: Double, allergy: String, windowDays: Int, name: String, amount: Double, acuity: Int, durationMinutes: Int, quantity: Int, status: FallbackOrderSetBatchStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.allergy = allergy
            self.windowDays = windowDays
            self.name = name
            self.amount = amount
            self.acuity = acuity
            self.durationMinutes = durationMinutes
            self.quantity = quantity
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

        func canMoveTo(_ next: FallbackOrderSetBatchStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == FallbackOrderSetBatchStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackOrderSetBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback order set batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedVolume() -> Double {
            return (amount * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> FallbackOrderSetBatch {
            return FallbackOrderSetBatch(
                code: code,
                label: label,
                cost: cost,
                allergy: allergy,
                windowDays: windowDays,
                name: name,
                amount: amount,
                acuity: acuity,
                durationMinutes: durationMinutes,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback order set batch in status open.
    static func newFallbackOrderSetBatch(_ code: String, label: String) -> FallbackOrderSetBatch {
        return FallbackOrderSetBatch(
            code: code,
            label: label,
            cost: 0.0,
            allergy: "",
            windowDays: 0,
            name: "",
            amount: 0.0,
            acuity: 0,
            durationMinutes: 0,
            quantity: 0,
            status: FallbackOrderSetBatchStatus.`open`
        )
    }
}
