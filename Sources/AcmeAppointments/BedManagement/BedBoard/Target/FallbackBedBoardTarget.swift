import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback bed board target is in its life cycle.
    enum FallbackBedBoardTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a fallback bed board target and its current status.
    final class FallbackBedBoardTarget {
        var code: String
        var label: String
        var amount: Double
        var currency: String
        var durationMinutes: Int
        var quantity: Int
        var description: String
        var procedureCode: String
        var status: FallbackBedBoardTargetStatus

        init(code: String, label: String, amount: Double, currency: String, durationMinutes: Int, quantity: Int, description: String, procedureCode: String, status: FallbackBedBoardTargetStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.currency = currency
            self.durationMinutes = durationMinutes
            self.quantity = quantity
            self.description = description
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackBedBoardTargetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FallbackBedBoardTargetStatus.rejected
            case .approved:
                return next == FallbackBedBoardTargetStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: FallbackBedBoardTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback bed board target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveExposure() -> Double {
            return ((amount + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackBedBoardTarget {
            return FallbackBedBoardTarget(
                code: code,
                label: label,
                amount: amount,
                currency: currency,
                durationMinutes: durationMinutes,
                quantity: quantity,
                description: description,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback bed board target in status proposed.
    static func newFallbackBedBoardTarget(_ code: String, label: String) -> FallbackBedBoardTarget {
        return FallbackBedBoardTarget(
            code: code,
            label: label,
            amount: 0.0,
            currency: "",
            durationMinutes: 0,
            quantity: 0,
            description: "",
            procedureCode: "",
            status: FallbackBedBoardTargetStatus.proposed
        )
    }
}
