import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix rule is in its life cycle.
    enum SkillMixRuleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a skill mix rule and its current status.
    final class SkillMixRule {
        var code: String
        var name: String
        var region: String
        var ownerID: String
        var segment: String
        var amount: Double
        var status: SkillMixRuleStatus

        init(code: String, name: String, region: String, ownerID: String, segment: String, amount: Double, status: SkillMixRuleStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.ownerID = ownerID
            self.segment = segment
            self.amount = amount
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

        func canMoveTo(_ next: SkillMixRuleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
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

        func moveTo(_ next: SkillMixRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> SkillMixRule {
            return SkillMixRule(
                code: code,
                name: name,
                region: region,
                ownerID: ownerID,
                segment: segment,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a skill mix rule in status planned.
    static func newSkillMixRule(_ code: String, name: String) -> SkillMixRule {
        return SkillMixRule(
            code: code,
            name: name,
            region: "",
            ownerID: "",
            segment: "",
            amount: 0.0,
            status: SkillMixRuleStatus.planned
        )
    }
}
