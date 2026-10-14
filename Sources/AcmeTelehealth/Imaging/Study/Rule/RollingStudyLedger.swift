import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling study ledger is in its life cycle.
    enum RollingStudyLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling study ledger as the study team keeps it.
    final class RollingStudyLedger {
        var code: String
        var label: String
        var copay: Double
        var durationMinutes: Int
        var batchSize: Int
        var threshold: Double
        var capacity: Int
        var discount: Double
        var status: RollingStudyLedgerStatus

        init(code: String, label: String, copay: Double, durationMinutes: Int, batchSize: Int, threshold: Double, capacity: Int, discount: Double, status: RollingStudyLedgerStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.durationMinutes = durationMinutes
            self.batchSize = batchSize
            self.threshold = threshold
            self.capacity = capacity
            self.discount = discount
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

        func canMoveTo(_ next: RollingStudyLedgerStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == RollingStudyLedgerStatus.closed
            case .active:
                return next == RollingStudyLedgerStatus.closed
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

        func moveTo(_ next: RollingStudyLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling study ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netValue() -> Double {
            return (Double(capacity) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RollingStudyLedger {
            return RollingStudyLedger(
                code: code,
                label: label,
                copay: copay,
                durationMinutes: durationMinutes,
                batchSize: batchSize,
                threshold: threshold,
                capacity: capacity,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling study ledger in status draft.
    static func newRollingStudyLedger(_ code: String, label: String) -> RollingStudyLedger {
        return RollingStudyLedger(
            code: code,
            label: label,
            copay: 0.0,
            durationMinutes: 0,
            batchSize: 0,
            threshold: 0.0,
            capacity: 0,
            discount: 0.0,
            status: RollingStudyLedgerStatus.draft
        )
    }
}
