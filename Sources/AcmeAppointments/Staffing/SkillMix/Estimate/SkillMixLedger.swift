import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix ledger is in its life cycle.
    enum SkillMixLedgerStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a skill mix ledger and its current status.
    final class SkillMixLedger {
        var code: String
        var label: String
        var active: Bool
        var amount: Double
        var maximum: Double
        var tags: [String]
        var copay: Double
        var encounterID: String
        var limit: Int
        var status: SkillMixLedgerStatus

        init(code: String, label: String, active: Bool, amount: Double, maximum: Double, tags: [String], copay: Double, encounterID: String, limit: Int, status: SkillMixLedgerStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.amount = amount
            self.maximum = maximum
            self.tags = tags
            self.copay = copay
            self.encounterID = encounterID
            self.limit = limit
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

        func canMoveTo(_ next: SkillMixLedgerStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: SkillMixLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return ((copay + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixLedger {
            return SkillMixLedger(
                code: code,
                label: label,
                active: active,
                amount: amount,
                maximum: maximum,
                tags: tags,
                copay: copay,
                encounterID: encounterID,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a skill mix ledger in status planned.
    static func newSkillMixLedger(_ code: String, label: String) -> SkillMixLedger {
        return SkillMixLedger(
            code: code,
            label: label,
            active: false,
            amount: 0.0,
            maximum: 0.0,
            tags: [],
            copay: 0.0,
            encounterID: "",
            limit: 0,
            status: SkillMixLedgerStatus.planned
        )
    }
}
