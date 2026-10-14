import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary care protocol ledger is in its life cycle.
    enum PrimaryCareProtocolLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary care protocol ledger. Its code is unique within a tenant.
    final class PrimaryCareProtocolLedger {
        var code: String
        var title: String
        var reviewer: String
        var procedureCode: String
        var refills: Int
        var status: PrimaryCareProtocolLedgerStatus

        init(code: String, title: String, reviewer: String, procedureCode: String, refills: Int, status: PrimaryCareProtocolLedgerStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.procedureCode = procedureCode
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryCareProtocolLedgerStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryCareProtocolLedgerStatus.published
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PrimaryCareProtocolLedgerStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryCareProtocolLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary care protocol ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> PrimaryCareProtocolLedger {
            return PrimaryCareProtocolLedger(
                code: code,
                title: title,
                reviewer: reviewer,
                procedureCode: procedureCode,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary care protocol ledger in status created.
    static func newPrimaryCareProtocolLedger(_ code: String, title: String) -> PrimaryCareProtocolLedger {
        return PrimaryCareProtocolLedger(
            code: code,
            title: title,
            reviewer: "",
            procedureCode: "",
            refills: 0,
            status: PrimaryCareProtocolLedgerStatus.created
        )
    }
}
