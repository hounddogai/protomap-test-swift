import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix profile must pass. Check returns its problems, or none.
    protocol SkillMixProfileRule {
        func check(_ item: SkillMixProfile) -> [String]
    }

    final class SkillMixProfileCodePrefixRule: SkillMixProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixProfileCopayRangeRule: SkillMixProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixProfile) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixProfileRequiredLabelRule: SkillMixProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixProfile) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix profile.
    final class SkillMixProfileValidator {
        var rules: [any SkillMixProfileRule]

        init(rules: [any SkillMixProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixProfile) -> [String] {
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

        func requireValid(_ item: SkillMixProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixProfile]) -> [String: [String]] {
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

    static func defaultSkillMixProfileValidator() -> SkillMixProfileValidator {
        return SkillMixProfileValidator(
            rules: [
                SkillMixProfileCodePrefixRule(prefix: "OPS"),
                SkillMixProfileCopayRangeRule(min: 5.6, max: 3537.2),
                SkillMixProfileRequiredLabelRule(message: "skill mix profile needs a value"),
            ]
        )
    }
}
