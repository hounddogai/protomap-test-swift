import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling census ledger is in its life cycle.
    enum RollingCensusLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rolling census ledger as the census team keeps it.
    final class RollingCensusLedger {
        var code: String
        var name: String
        var dosageMg: Double
        var locale: String
        var windowDays: Int
        var graceDays: Int
        var pinned: Bool
        var status: RollingCensusLedgerStatus

        init(code: String, name: String, dosageMg: Double, locale: String, windowDays: Int, graceDays: Int, pinned: Bool, status: RollingCensusLedgerStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.locale = locale
            self.windowDays = windowDays
            self.graceDays = graceDays
            self.pinned = pinned
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

        func canMoveTo(_ next: RollingCensusLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RollingCensusLedgerStatus.resolved || next == RollingCensusLedgerStatus.reopened
            case .resolved:
                return next == RollingCensusLedgerStatus.reopened || next == RollingCensusLedgerStatus.archived
            case .reopened:
                return next == RollingCensusLedgerStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCensusLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling census ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling census ledger") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(windowDays) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> RollingCensusLedger {
            return RollingCensusLedger(
                code: code,
                name: name,
                dosageMg: dosageMg,
                locale: locale,
                windowDays: windowDays,
                graceDays: graceDays,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rolling census ledger in status open.
    static func newRollingCensusLedger(_ code: String, name: String) -> RollingCensusLedger {
        return RollingCensusLedger(
            code: code,
            name: name,
            dosageMg: 0.0,
            locale: "",
            windowDays: 0,
            graceDays: 0,
            pinned: false,
            status: RollingCensusLedgerStatus.`open`
        )
    }
}
