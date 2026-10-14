import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel ledger is in its life cycle.
    enum PanelLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One panel ledger, with what the planners need to act on it.
    final class PanelLedger {
        var code: String
        var label: String
        var quantity: Int
        var retries: Int
        var diagnosisCode: String
        var status: PanelLedgerStatus

        init(code: String, label: String, quantity: Int, retries: Int, diagnosisCode: String, status: PanelLedgerStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.retries = retries
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: PanelLedgerStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == PanelLedgerStatus.suspended || next == PanelLedgerStatus.closed
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

        func moveTo(_ next: PanelLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedTotal() -> Double {
            return (Double(retries) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> PanelLedger {
            return PanelLedger(
                code: code,
                label: label,
                quantity: quantity,
                retries: retries,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a panel ledger in status draft.
    static func newPanelLedger(_ code: String, label: String) -> PanelLedger {
        return PanelLedger(
            code: code,
            label: label,
            quantity: 0,
            retries: 0,
            diagnosisCode: "",
            status: PanelLedgerStatus.draft
        )
    }
}
