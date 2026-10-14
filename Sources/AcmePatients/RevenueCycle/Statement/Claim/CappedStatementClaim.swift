import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped statement claim is in its life cycle.
    enum CappedStatementClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a capped statement claim and its current status.
    final class CappedStatementClaim {
        var code: String
        var name: String
        var procedureCode: String
        var notes: String
        var externalRef: String
        var unit: String
        var amount: Double
        var status: CappedStatementClaimStatus

        init(code: String, name: String, procedureCode: String, notes: String, externalRef: String, unit: String, amount: Double, status: CappedStatementClaimStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.notes = notes
            self.externalRef = externalRef
            self.unit = unit
            self.amount = amount
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

        func canMoveTo(_ next: CappedStatementClaimStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CappedStatementClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped statement claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped statement claim") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> CappedStatementClaim {
            return CappedStatementClaim(
                code: code,
                name: name,
                procedureCode: procedureCode,
                notes: notes,
                externalRef: externalRef,
                unit: unit,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped statement claim in status draft.
    static func newCappedStatementClaim(_ code: String, name: String) -> CappedStatementClaim {
        return CappedStatementClaim(
            code: code,
            name: name,
            procedureCode: "",
            notes: "",
            externalRef: "",
            unit: "",
            amount: 0.0,
            status: CappedStatementClaimStatus.draft
        )
    }
}
