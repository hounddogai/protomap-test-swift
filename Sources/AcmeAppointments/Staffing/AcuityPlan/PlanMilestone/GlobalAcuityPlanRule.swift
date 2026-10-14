import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global acuity plan rule is in its life cycle.
    enum GlobalAcuityPlanRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global acuity plan rule. Its code is unique within a tenant.
    final class GlobalAcuityPlanRule {
        var code: String
        var title: String
        var tags: [String]
        var timezone: String
        var ceiling: Double
        var status: GlobalAcuityPlanRuleStatus

        init(code: String, title: String, tags: [String], timezone: String, ceiling: Double, status: GlobalAcuityPlanRuleStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.timezone = timezone
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalAcuityPlanRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == GlobalAcuityPlanRuleStatus.done || next == GlobalAcuityPlanRuleStatus.failed
            case .running:
                return next == GlobalAcuityPlanRuleStatus.done
            case .done:
                return next == GlobalAcuityPlanRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalAcuityPlanRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global acuity plan rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global acuity plan rule") \(code)"
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
            return ceiling
        }

        func copyValue() -> GlobalAcuityPlanRule {
            return GlobalAcuityPlanRule(
                code: code,
                title: title,
                tags: tags,
                timezone: timezone,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global acuity plan rule in status new.
    static func newGlobalAcuityPlanRule(_ code: String, title: String) -> GlobalAcuityPlanRule {
        return GlobalAcuityPlanRule(
            code: code,
            title: title,
            tags: [],
            timezone: "",
            ceiling: 0.0,
            status: GlobalAcuityPlanRuleStatus.new
        )
    }
}
