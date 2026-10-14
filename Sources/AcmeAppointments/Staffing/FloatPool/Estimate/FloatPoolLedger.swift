import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool ledger is in its life cycle.
    enum FloatPoolLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A float pool ledger. Its code is unique within a tenant.
    final class FloatPoolLedger {
        var code: String
        var label: String
        var threshold: Double
        var windowDays: Int
        var pinned: Bool
        var amount: Double
        var status: FloatPoolLedgerStatus

        init(code: String, label: String, threshold: Double, windowDays: Int, pinned: Bool, amount: Double, status: FloatPoolLedgerStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.windowDays = windowDays
            self.pinned = pinned
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FloatPoolLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FloatPoolLedgerStatus.reopened || next == FloatPoolLedgerStatus.archived
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: FloatPoolLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("float pool ledger") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((amount + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolLedger {
            return FloatPoolLedger(
                code: code,
                label: label,
                threshold: threshold,
                windowDays: windowDays,
                pinned: pinned,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a float pool ledger in status open.
    static func newFloatPoolLedger(_ code: String, label: String) -> FloatPoolLedger {
        return FloatPoolLedger(
            code: code,
            label: label,
            threshold: 0.0,
            windowDays: 0,
            pinned: false,
            amount: 0.0,
            status: FloatPoolLedgerStatus.`open`
        )
    }
}
