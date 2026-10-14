import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan ledger is in its life cycle.
    enum DischargePlanLedgerStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A discharge plan ledger. Its code is unique within a tenant.
    final class DischargePlanLedger {
        var code: String
        var name: String
        var patientRef: String
        var budget: Double
        var rate: Double
        var status: DischargePlanLedgerStatus

        init(code: String, name: String, patientRef: String, budget: Double, rate: Double, status: DischargePlanLedgerStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.budget = budget
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DischargePlanLedgerStatus) -> Bool {
            switch status {
            case .requested:
                return next == DischargePlanLedgerStatus.revoked
            case .granted:
                return next == DischargePlanLedgerStatus.revoked || next == DischargePlanLedgerStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: DischargePlanLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveValue() -> Double {
            return (budget * rate * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanLedger {
            return DischargePlanLedger(
                code: code,
                name: name,
                patientRef: patientRef,
                budget: budget,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a discharge plan ledger in status requested.
    static func newDischargePlanLedger(_ code: String, name: String) -> DischargePlanLedger {
        return DischargePlanLedger(
            code: code,
            name: name,
            patientRef: "",
            budget: 0.0,
            rate: 0.0,
            status: DischargePlanLedgerStatus.requested
        )
    }
}
