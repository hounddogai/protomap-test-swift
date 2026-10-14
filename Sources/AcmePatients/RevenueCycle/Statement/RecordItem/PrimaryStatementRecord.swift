import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary statement record is in its life cycle.
    enum PrimaryStatementRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a primary statement record and its current status.
    final class PrimaryStatementRecord {
        var code: String
        var name: String
        var acuity: Int
        var dosageMg: Double
        var refills: Int
        var currency: String
        var payer: String
        var externalRef: String
        var status: PrimaryStatementRecordStatus

        init(code: String, name: String, acuity: Int, dosageMg: Double, refills: Int, currency: String, payer: String, externalRef: String, status: PrimaryStatementRecordStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.dosageMg = dosageMg
            self.refills = refills
            self.currency = currency
            self.payer = payer
            self.externalRef = externalRef
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

        func canMoveTo(_ next: PrimaryStatementRecordStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryStatementRecordStatus.active || next == PrimaryStatementRecordStatus.closed
            case .pending:
                return next == PrimaryStatementRecordStatus.active || next == PrimaryStatementRecordStatus.suspended
            case .active:
                switch next {
                case .suspended:
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

        func moveTo(_ next: PrimaryStatementRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary statement record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary statement record") \(code)"
        }

        func projectedExposure() -> Double {
            return (Double(refills) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> PrimaryStatementRecord {
            return PrimaryStatementRecord(
                code: code,
                name: name,
                acuity: acuity,
                dosageMg: dosageMg,
                refills: refills,
                currency: currency,
                payer: payer,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary statement record in status draft.
    static func newPrimaryStatementRecord(_ code: String, name: String) -> PrimaryStatementRecord {
        return PrimaryStatementRecord(
            code: code,
            name: name,
            acuity: 0,
            dosageMg: 0.0,
            refills: 0,
            currency: "",
            payer: "",
            externalRef: "",
            status: PrimaryStatementRecordStatus.draft
        )
    }
}
