import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy substitution ledger is in its life cycle.
    enum LegacySubstitutionLedgerStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a legacy substitution ledger and its current status.
    final class LegacySubstitutionLedger {
        var code: String
        var title: String
        var priority: Int
        var threshold: Double
        var procedureCode: String
        var status: LegacySubstitutionLedgerStatus

        init(code: String, title: String, priority: Int, threshold: Double, procedureCode: String, status: LegacySubstitutionLedgerStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.threshold = threshold
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: LegacySubstitutionLedgerStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LegacySubstitutionLedgerStatus.draining || next == LegacySubstitutionLedgerStatus.stopped
            case .ready:
                return next == LegacySubstitutionLedgerStatus.draining
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

        func moveTo(_ next: LegacySubstitutionLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy substitution ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy substitution ledger") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(priority) * threshold * 100).rounded() / 100
        }

        func copyValue() -> LegacySubstitutionLedger {
            return LegacySubstitutionLedger(
                code: code,
                title: title,
                priority: priority,
                threshold: threshold,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy substitution ledger in status idle.
    static func newLegacySubstitutionLedger(_ code: String, title: String) -> LegacySubstitutionLedger {
        return LegacySubstitutionLedger(
            code: code,
            title: title,
            priority: 0,
            threshold: 0.0,
            procedureCode: "",
            status: LegacySubstitutionLedgerStatus.idle
        )
    }
}
