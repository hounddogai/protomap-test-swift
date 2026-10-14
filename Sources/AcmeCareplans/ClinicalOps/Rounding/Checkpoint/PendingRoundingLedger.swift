import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending rounding ledger is in its life cycle.
    enum PendingRoundingLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending rounding ledger. Its code is unique within a tenant.
    final class PendingRoundingLedger {
        var code: String
        var name: String
        var tags: [String]
        var diagnosisCode: String
        var capacity: Int
        var status: PendingRoundingLedgerStatus

        init(code: String, name: String, tags: [String], diagnosisCode: String, capacity: Int, status: PendingRoundingLedgerStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.diagnosisCode = diagnosisCode
            self.capacity = capacity
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

        func canMoveTo(_ next: PendingRoundingLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingRoundingLedgerStatus.resolved || next == PendingRoundingLedgerStatus.reopened
            case .inReview:
                switch next {
                case .reopened, .archived:
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

        func moveTo(_ next: PendingRoundingLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending rounding ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending rounding ledger") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> PendingRoundingLedger {
            return PendingRoundingLedger(
                code: code,
                name: name,
                tags: tags,
                diagnosisCode: diagnosisCode,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending rounding ledger in status open.
    static func newPendingRoundingLedger(_ code: String, name: String) -> PendingRoundingLedger {
        return PendingRoundingLedger(
            code: code,
            name: name,
            tags: [],
            diagnosisCode: "",
            capacity: 0,
            status: PendingRoundingLedgerStatus.`open`
        )
    }
}
