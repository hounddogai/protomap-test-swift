import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled acuity plan rule must pass. Check returns its problems, or none.
    protocol ScheduledAcuityPlanRuleRule {
        func check(_ item: ScheduledAcuityPlanRule) -> [String]
    }

    final class ScheduledAcuityPlanRuleRequiredPhoneRule: ScheduledAcuityPlanRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAcuityPlanRule) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAcuityPlanRuleAcuityRangeRule: ScheduledAcuityPlanRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledAcuityPlanRule) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledAcuityPlanRuleAllowedContactEmailRule: ScheduledAcuityPlanRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledAcuityPlanRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is inconsistent"]
            }
            return []
        }
    }

    final class ScheduledAcuityPlanRuleCodePrefixRule: ScheduledAcuityPlanRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledAcuityPlanRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledAcuityPlanRulePhoneLengthRule: ScheduledAcuityPlanRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAcuityPlanRule) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledAcuityPlanRuleRequiredContactEmailRule: ScheduledAcuityPlanRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAcuityPlanRule) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled acuity plan rule.
    final class ScheduledAcuityPlanRuleValidator {
        var rules: [any ScheduledAcuityPlanRuleRule]

        init(rules: [any ScheduledAcuityPlanRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAcuityPlanRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledAcuityPlanRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAcuityPlanRule]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultScheduledAcuityPlanRuleValidator() -> ScheduledAcuityPlanRuleValidator {
        return ScheduledAcuityPlanRuleValidator(
            rules: [
                ScheduledAcuityPlanRuleRequiredPhoneRule(message: "scheduled acuity plan rule needs this field"),
                ScheduledAcuityPlanRuleAcuityRangeRule(min: 255, max: 86400),
                ScheduledAcuityPlanRuleAllowedContactEmailRule(allowed: []),
                ScheduledAcuityPlanRuleCodePrefixRule(prefix: "REF"),
                ScheduledAcuityPlanRulePhoneLengthRule(maxLength: 1000),
                ScheduledAcuityPlanRuleRequiredContactEmailRule(message: "scheduled acuity plan rule needs an entry"),
            ]
        )
    }
}
