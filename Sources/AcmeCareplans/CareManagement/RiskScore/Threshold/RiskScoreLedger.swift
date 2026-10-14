import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score ledger is in its life cycle.
    enum RiskScoreLedgerStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One risk score ledger, with what the planners need to act on it.
    final class RiskScoreLedger {
        var code: String
        var label: String
        var approved: Bool
        var currency: String
        var revision: Int
        var status: RiskScoreLedgerStatus

        init(code: String, label: String, approved: Bool, currency: String, revision: Int, status: RiskScoreLedgerStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.currency = currency
            self.revision = revision
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

        func canMoveTo(_ next: RiskScoreLedgerStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RiskScoreLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("risk score ledger") \(code)"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> RiskScoreLedger {
            return RiskScoreLedger(
                code: code,
                label: label,
                approved: approved,
                currency: currency,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a risk score ledger in status planned.
    static func newRiskScoreLedger(_ code: String, label: String) -> RiskScoreLedger {
        return RiskScoreLedger(
            code: code,
            label: label,
            approved: false,
            currency: "",
            revision: 0,
            status: RiskScoreLedgerStatus.planned
        )
    }
}
