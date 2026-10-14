import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a legacy overtime policy must pass. Check returns its problems, or none.
    protocol LegacyOvertimePolicyRule {
        func check(_ item: LegacyOvertimePolicy) -> [String]
    }

    final class LegacyOvertimePolicyCodeLengthRule: LegacyOvertimePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOvertimePolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyOvertimePolicyChannelLengthRule: LegacyOvertimePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOvertimePolicy) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyOvertimePolicyRequiredChannelRule: LegacyOvertimePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyOvertimePolicy) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyOvertimePolicyFloorValueRangeRule: LegacyOvertimePolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyOvertimePolicy) -> [String] {
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

    /// Runs every rule of a legacy overtime policy.
    final class LegacyOvertimePolicyValidator {
        var rules: [any LegacyOvertimePolicyRule]

        init(rules: [any LegacyOvertimePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyOvertimePolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyOvertimePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyOvertimePolicy]) -> [String: [String]] {
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

    static func defaultLegacyOvertimePolicyValidator() -> LegacyOvertimePolicyValidator {
        return LegacyOvertimePolicyValidator(
            rules: [
                LegacyOvertimePolicyCodeLengthRule(maxLength: 1000),
                LegacyOvertimePolicyChannelLengthRule(maxLength: 3600),
                LegacyOvertimePolicyRequiredChannelRule(message: "legacy overtime policy needs a value"),
                LegacyOvertimePolicyFloorValueRangeRule(min: 1.2, max: 4399.3),
            ]
        )
    }
}
