import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix variance must pass. Check returns its problems, or none.
    protocol SkillMixVarianceRule {
        func check(_ item: SkillMixVariance) -> [String]
    }

    final class SkillMixVarianceRequiredCodeRule: SkillMixVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixVarianceCodeLengthRule: SkillMixVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixVarianceGraceDaysRangeRule: SkillMixVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixVariance) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixVarianceCodePrefixRule: SkillMixVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixVarianceWeightRangeRule: SkillMixVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixVariance) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix variance.
    final class SkillMixVarianceValidator {
        var rules: [any SkillMixVarianceRule]

        init(rules: [any SkillMixVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixVariance]) -> [String: [String]] {
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

    static func defaultSkillMixVarianceValidator() -> SkillMixVarianceValidator {
        return SkillMixVarianceValidator(
            rules: [
                SkillMixVarianceRequiredCodeRule(message: "skill mix variance needs an entry"),
                SkillMixVarianceCodeLengthRule(maxLength: 32),
                SkillMixVarianceGraceDaysRangeRule(min: 120, max: 86400),
                SkillMixVarianceCodePrefixRule(prefix: "Q"),
                SkillMixVarianceWeightRangeRule(min: 5.5, max: 840.0),
            ]
        )
    }
}
