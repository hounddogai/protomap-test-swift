import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling discharge plan rule must pass. Check returns its problems, or none.
    protocol RollingDischargePlanRuleRule {
        func check(_ item: RollingDischargePlanRule) -> [String]
    }

    final class RollingDischargePlanRuleFloorValueRangeRule: RollingDischargePlanRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingDischargePlanRule) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingDischargePlanRuleCodePrefixRule: RollingDischargePlanRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingDischargePlanRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingDischargePlanRuleRequiredChannelRule: RollingDischargePlanRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDischargePlanRule) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDischargePlanRuleChannelLengthRule: RollingDischargePlanRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingDischargePlanRule) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingDischargePlanRuleRequiredCodeRule: RollingDischargePlanRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDischargePlanRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDischargePlanRuleRequiredNameRule: RollingDischargePlanRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDischargePlanRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling discharge plan rule.
    final class RollingDischargePlanRuleValidator {
        var rules: [any RollingDischargePlanRuleRule]

        init(rules: [any RollingDischargePlanRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingDischargePlanRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingDischargePlanRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingDischargePlanRule]) -> [String: [String]] {
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

    static func defaultRollingDischargePlanRuleValidator() -> RollingDischargePlanRuleValidator {
        return RollingDischargePlanRuleValidator(
            rules: [
                RollingDischargePlanRuleFloorValueRangeRule(min: 2.8, max: 4579.9),
                RollingDischargePlanRuleCodePrefixRule(prefix: "OPS"),
                RollingDischargePlanRuleRequiredChannelRule(message: "rolling discharge plan rule needs an entry"),
                RollingDischargePlanRuleChannelLengthRule(maxLength: 16),
                RollingDischargePlanRuleRequiredCodeRule(message: "rolling discharge plan rule needs an entry"),
                RollingDischargePlanRuleRequiredNameRule(message: "rolling discharge plan rule needs an entry"),
            ]
        )
    }
}
