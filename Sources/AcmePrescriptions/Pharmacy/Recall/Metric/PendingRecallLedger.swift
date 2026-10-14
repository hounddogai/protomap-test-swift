import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending recall ledger is in its life cycle.
    enum PendingRecallLedgerStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One pending recall ledger, with what the planners need to act on it.
    final class PendingRecallLedger {
        var code: String
        var label: String
        var ratio: Double
        var retries: Int
        var unit: String
        var status: PendingRecallLedgerStatus

        init(code: String, label: String, ratio: Double, retries: Int, unit: String, status: PendingRecallLedgerStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.retries = retries
            self.unit = unit
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

        func canMoveTo(_ next: PendingRecallLedgerStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PendingRecallLedgerStatus.draining || next == PendingRecallLedgerStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PendingRecallLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending recall ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending recall ledger") \(code)"
        }

        func netVolume() -> Double {
            return ((ratio + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PendingRecallLedger {
            return PendingRecallLedger(
                code: code,
                label: label,
                ratio: ratio,
                retries: retries,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending recall ledger in status idle.
    static func newPendingRecallLedger(_ code: String, label: String) -> PendingRecallLedger {
        return PendingRecallLedger(
            code: code,
            label: label,
            ratio: 0.0,
            retries: 0,
            unit: "",
            status: PendingRecallLedgerStatus.idle
        )
    }
}
