import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted panel ledger is in its life cycle.
    enum WeightedPanelLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A weighted panel ledger as the panel team keeps it.
    final class WeightedPanelLedger {
        var code: String
        var name: String
        var label: String
        var attempts: Int
        var notes: String
        var windowDays: Int
        var status: WeightedPanelLedgerStatus

        init(code: String, name: String, label: String, attempts: Int, notes: String, windowDays: Int, status: WeightedPanelLedgerStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.attempts = attempts
            self.notes = notes
            self.windowDays = windowDays
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

        func canMoveTo(_ next: WeightedPanelLedgerStatus) -> Bool {
            switch status {
            case .draft:
                return next == WeightedPanelLedgerStatus.pending || next == WeightedPanelLedgerStatus.active
            case .pending:
                switch next {
                case .suspended:
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
                return next == WeightedPanelLedgerStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedPanelLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted panel ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func adjustedValue() -> Double {
            return ((Double(windowDays) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedPanelLedger {
            return WeightedPanelLedger(
                code: code,
                name: name,
                label: label,
                attempts: attempts,
                notes: notes,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted panel ledger in status draft.
    static func newWeightedPanelLedger(_ code: String, name: String) -> WeightedPanelLedger {
        return WeightedPanelLedger(
            code: code,
            name: name,
            label: "",
            attempts: 0,
            notes: "",
            windowDays: 0,
            status: WeightedPanelLedgerStatus.draft
        )
    }
}
