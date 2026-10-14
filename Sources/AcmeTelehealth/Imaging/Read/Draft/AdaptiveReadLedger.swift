import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive read ledger is in its life cycle.
    enum AdaptiveReadLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One adaptive read ledger, with what the planners need to act on it.
    final class AdaptiveReadLedger {
        var code: String
        var label: String
        var updatedAt: Int
        var ceiling: Double
        var facility: String
        var status: AdaptiveReadLedgerStatus

        init(code: String, label: String, updatedAt: Int, ceiling: Double, facility: String, status: AdaptiveReadLedgerStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.facility = facility
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

        func canMoveTo(_ next: AdaptiveReadLedgerStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == AdaptiveReadLedgerStatus.suspended || next == AdaptiveReadLedgerStatus.closed
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

        func moveTo(_ next: AdaptiveReadLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive read ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive read ledger") \(code)"
        }

        func projectedVolume() -> Double {
            return (Double(updatedAt) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveReadLedger {
            return AdaptiveReadLedger(
                code: code,
                label: label,
                updatedAt: updatedAt,
                ceiling: ceiling,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a adaptive read ledger in status draft.
    static func newAdaptiveReadLedger(_ code: String, label: String) -> AdaptiveReadLedger {
        return AdaptiveReadLedger(
            code: code,
            label: label,
            updatedAt: 0,
            ceiling: 0.0,
            facility: "",
            status: AdaptiveReadLedgerStatus.draft
        )
    }
}
