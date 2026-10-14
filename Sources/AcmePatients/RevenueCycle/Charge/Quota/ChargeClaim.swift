import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge claim is in its life cycle.
    enum ChargeClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A charge claim. Its code is unique within a tenant.
    final class ChargeClaim {
        var code: String
        var title: String
        var externalRef: String
        var ceiling: Double
        var unit: String
        var status: ChargeClaimStatus

        init(code: String, title: String, externalRef: String, ceiling: Double, unit: String, status: ChargeClaimStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.ceiling = ceiling
            self.unit = unit
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

        func canMoveTo(_ next: ChargeClaimStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ChargeClaimStatus.rejected || next == ChargeClaimStatus.withdrawn
            case .approved:
                return next == ChargeClaimStatus.withdrawn
            case .rejected:
                return next == ChargeClaimStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> ChargeClaim {
            return ChargeClaim(
                code: code,
                title: title,
                externalRef: externalRef,
                ceiling: ceiling,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a charge claim in status proposed.
    static func newChargeClaim(_ code: String, title: String) -> ChargeClaim {
        return ChargeClaim(
            code: code,
            title: title,
            externalRef: "",
            ceiling: 0.0,
            unit: "",
            status: ChargeClaimStatus.proposed
        )
    }
}
