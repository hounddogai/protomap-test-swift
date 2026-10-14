import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback transfer plan is in its life cycle.
    enum FallbackTransferPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback transfer plan as the transfer team keeps it.
    final class FallbackTransferPlan {
        var code: String
        var label: String
        var copay: Double
        var quantity: Int
        var checksum: String
        var rate: Double
        var patientRef: String
        var status: FallbackTransferPlanStatus

        init(code: String, label: String, copay: Double, quantity: Int, checksum: String, rate: Double, patientRef: String, status: FallbackTransferPlanStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.quantity = quantity
            self.checksum = checksum
            self.rate = rate
            self.patientRef = patientRef
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

        func canMoveTo(_ next: FallbackTransferPlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FallbackTransferPlanStatus.approved
            case .approved:
                return next == FallbackTransferPlanStatus.rejected || next == FallbackTransferPlanStatus.withdrawn
            case .rejected:
                return next == FallbackTransferPlanStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackTransferPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback transfer plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback transfer plan") \(code)"
        }

        func netLoad() -> Double {
            return (rate * copay * 100).rounded() / 100
        }

        func copyValue() -> FallbackTransferPlan {
            return FallbackTransferPlan(
                code: code,
                label: label,
                copay: copay,
                quantity: quantity,
                checksum: checksum,
                rate: rate,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback transfer plan in status proposed.
    static func newFallbackTransferPlan(_ code: String, label: String) -> FallbackTransferPlan {
        return FallbackTransferPlan(
            code: code,
            label: label,
            copay: 0.0,
            quantity: 0,
            checksum: "",
            rate: 0.0,
            patientRef: "",
            status: FallbackTransferPlanStatus.proposed
        )
    }
}
