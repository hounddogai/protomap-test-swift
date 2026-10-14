import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix allocation must pass. Check returns its problems, or none.
    protocol SkillMixAllocationRule {
        func check(_ item: SkillMixAllocation) -> [String]
    }

    final class SkillMixAllocationCodePrefixRule: SkillMixAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixAllocationRequiredCodeRule: SkillMixAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixAllocationCeilingRangeRule: SkillMixAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixAllocation) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixAllocationRequiredNotesRule: SkillMixAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixAllocation) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixAllocationNotesLengthRule: SkillMixAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixAllocation) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix allocation.
    final class SkillMixAllocationValidator {
        var rules: [any SkillMixAllocationRule]

        init(rules: [any SkillMixAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixAllocation]) -> [String: [String]] {
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

    static func defaultSkillMixAllocationValidator() -> SkillMixAllocationValidator {
        return SkillMixAllocationValidator(
            rules: [
                SkillMixAllocationCodePrefixRule(prefix: "ACM"),
                SkillMixAllocationRequiredCodeRule(message: "skill mix allocation needs a value"),
                SkillMixAllocationCeilingRangeRule(min: 8.6, max: 851.7),
                SkillMixAllocationRequiredNotesRule(message: "skill mix allocation needs an entry"),
                SkillMixAllocationNotesLengthRule(maxLength: 1000),
            ]
        )
    }
}
