import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure ledger is in its life cycle.
    enum DisclosureLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a disclosure ledger and its current status.
    final class DisclosureLedger {
        var code: String
        var label: String
        var durationMinutes: Int
        var visible: Bool
        var priority: Int
        var patientRef: String
        var copay: Double
        var procedureCode: String
        var status: DisclosureLedgerStatus

        init(code: String, label: String, durationMinutes: Int, visible: Bool, priority: Int, patientRef: String, copay: Double, procedureCode: String, status: DisclosureLedgerStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.visible = visible
            self.priority = priority
            self.patientRef = patientRef
            self.copay = copay
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: DisclosureLedgerStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
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
                case .suspended, .closed:
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

        func moveTo(_ next: DisclosureLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return ((Double(priority) + copay) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureLedger {
            return DisclosureLedger(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                visible: visible,
                priority: priority,
                patientRef: patientRef,
                copay: copay,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a disclosure ledger in status draft.
    static func newDisclosureLedger(_ code: String, label: String) -> DisclosureLedger {
        return DisclosureLedger(
            code: code,
            label: label,
            durationMinutes: 0,
            visible: false,
            priority: 0,
            patientRef: "",
            copay: 0.0,
            procedureCode: "",
            status: DisclosureLedgerStatus.draft
        )
    }
}
