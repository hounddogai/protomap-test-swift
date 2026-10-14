import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered read ledger is in its life cycle.
    enum TieredReadLedgerStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A tiered read ledger as the read team keeps it.
    final class TieredReadLedger {
        var code: String
        var name: String
        var label: String
        var copay: Double
        var source: String
        var status: TieredReadLedgerStatus

        init(code: String, name: String, label: String, copay: Double, source: String, status: TieredReadLedgerStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.copay = copay
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredReadLedgerStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == TieredReadLedgerStatus.ready || next == TieredReadLedgerStatus.stopped
            case .ready:
                return next == TieredReadLedgerStatus.draining || next == TieredReadLedgerStatus.stopped
            case .draining:
                return next == TieredReadLedgerStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredReadLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered read ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> TieredReadLedger {
            return TieredReadLedger(
                code: code,
                name: name,
                label: label,
                copay: copay,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a tiered read ledger in status idle.
    static func newTieredReadLedger(_ code: String, name: String) -> TieredReadLedger {
        return TieredReadLedger(
            code: code,
            name: name,
            label: "",
            copay: 0.0,
            source: "",
            status: TieredReadLedgerStatus.idle
        )
    }
}
