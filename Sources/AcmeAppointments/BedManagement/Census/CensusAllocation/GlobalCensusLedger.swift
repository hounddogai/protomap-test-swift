import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global census ledger is in its life cycle.
    enum GlobalCensusLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A global census ledger. Its code is unique within a tenant.
    final class GlobalCensusLedger {
        var code: String
        var label: String
        var specialty: String
        var expiresAt: Int
        var summary: String
        var status: GlobalCensusLedgerStatus

        init(code: String, label: String, specialty: String, expiresAt: Int, summary: String, status: GlobalCensusLedgerStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.expiresAt = expiresAt
            self.summary = summary
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

        func canMoveTo(_ next: GlobalCensusLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GlobalCensusLedgerStatus.resolved || next == GlobalCensusLedgerStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == GlobalCensusLedgerStatus.reopened
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

        func moveTo(_ next: GlobalCensusLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global census ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> GlobalCensusLedger {
            return GlobalCensusLedger(
                code: code,
                label: label,
                specialty: specialty,
                expiresAt: expiresAt,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global census ledger in status open.
    static func newGlobalCensusLedger(_ code: String, label: String) -> GlobalCensusLedger {
        return GlobalCensusLedger(
            code: code,
            label: label,
            specialty: "",
            expiresAt: 0,
            summary: "",
            status: GlobalCensusLedgerStatus.`open`
        )
    }
}
