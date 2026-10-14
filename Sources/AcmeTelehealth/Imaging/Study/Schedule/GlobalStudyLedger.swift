import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global study ledger is in its life cycle.
    enum GlobalStudyLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a global study ledger and its current status.
    final class GlobalStudyLedger {
        var code: String
        var name: String
        var score: Double
        var ceiling: Double
        var threshold: Double
        var visitMinutes: Int
        var version: Int
        var ownerID: String
        var phone: String
        var status: GlobalStudyLedgerStatus

        init(code: String, name: String, score: Double, ceiling: Double, threshold: Double, visitMinutes: Int, version: Int, ownerID: String, phone: String, status: GlobalStudyLedgerStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.ceiling = ceiling
            self.threshold = threshold
            self.visitMinutes = visitMinutes
            self.version = version
            self.ownerID = ownerID
            self.phone = phone
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

        func canMoveTo(_ next: GlobalStudyLedgerStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == GlobalStudyLedgerStatus.active
            case .active:
                return next == GlobalStudyLedgerStatus.suspended || next == GlobalStudyLedgerStatus.closed
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

        func moveTo(_ next: GlobalStudyLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global study ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("global study ledger") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(visitMinutes) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalStudyLedger {
            return GlobalStudyLedger(
                code: code,
                name: name,
                score: score,
                ceiling: ceiling,
                threshold: threshold,
                visitMinutes: visitMinutes,
                version: version,
                ownerID: ownerID,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global study ledger in status draft.
    static func newGlobalStudyLedger(_ code: String, name: String) -> GlobalStudyLedger {
        return GlobalStudyLedger(
            code: code,
            name: name,
            score: 0.0,
            ceiling: 0.0,
            threshold: 0.0,
            visitMinutes: 0,
            version: 0,
            ownerID: "",
            phone: "",
            status: GlobalStudyLedgerStatus.draft
        )
    }
}
