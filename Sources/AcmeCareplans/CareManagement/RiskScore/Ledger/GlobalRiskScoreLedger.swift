import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global risk score ledger is in its life cycle.
    enum GlobalRiskScoreLedgerStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global risk score ledger. Its code is unique within a tenant.
    final class GlobalRiskScoreLedger {
        var code: String
        var title: String
        var floorValue: Double
        var procedureCode: String
        var dosageMg: Double
        var status: GlobalRiskScoreLedgerStatus

        init(code: String, title: String, floorValue: Double, procedureCode: String, dosageMg: Double, status: GlobalRiskScoreLedgerStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.procedureCode = procedureCode
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalRiskScoreLedgerStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == GlobalRiskScoreLedgerStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: GlobalRiskScoreLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global risk score ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global risk score ledger") \(code)"
        }

        func netTotal() -> Double {
            return ((dosageMg + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> GlobalRiskScoreLedger {
            return GlobalRiskScoreLedger(
                code: code,
                title: title,
                floorValue: floorValue,
                procedureCode: procedureCode,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global risk score ledger in status planned.
    static func newGlobalRiskScoreLedger(_ code: String, title: String) -> GlobalRiskScoreLedger {
        return GlobalRiskScoreLedger(
            code: code,
            title: title,
            floorValue: 0.0,
            procedureCode: "",
            dosageMg: 0.0,
            status: GlobalRiskScoreLedgerStatus.planned
        )
    }
}
