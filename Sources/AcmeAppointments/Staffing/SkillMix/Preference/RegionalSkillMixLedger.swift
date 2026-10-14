import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional skill mix ledger is in its life cycle.
    enum RegionalSkillMixLedgerStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a regional skill mix ledger and its current status.
    final class RegionalSkillMixLedger {
        var code: String
        var title: String
        var discount: Double
        var pinned: Bool
        var batchSize: Int
        var sequence: Int
        var score: Double
        var status: RegionalSkillMixLedgerStatus

        init(code: String, title: String, discount: Double, pinned: Bool, batchSize: Int, sequence: Int, score: Double, status: RegionalSkillMixLedgerStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.pinned = pinned
            self.batchSize = batchSize
            self.sequence = sequence
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalSkillMixLedgerStatus) -> Bool {
            switch status {
            case .planned:
                return next == RegionalSkillMixLedgerStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RegionalSkillMixLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional skill mix ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional skill mix ledger") \(code)"
        }

        func effectiveValue() -> Double {
            return ((discount + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalSkillMixLedger {
            return RegionalSkillMixLedger(
                code: code,
                title: title,
                discount: discount,
                pinned: pinned,
                batchSize: batchSize,
                sequence: sequence,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional skill mix ledger in status planned.
    static func newRegionalSkillMixLedger(_ code: String, title: String) -> RegionalSkillMixLedger {
        return RegionalSkillMixLedger(
            code: code,
            title: title,
            discount: 0.0,
            pinned: false,
            batchSize: 0,
            sequence: 0,
            score: 0.0,
            status: RegionalSkillMixLedgerStatus.planned
        )
    }
}
