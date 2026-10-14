import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback skill mix template must pass. Check returns its problems, or none.
    protocol FallbackSkillMixTemplateRule {
        func check(_ item: FallbackSkillMixTemplate) -> [String]
    }

    final class FallbackSkillMixTemplateDiscountRangeRule: FallbackSkillMixTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackSkillMixTemplate) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackSkillMixTemplateVersionRangeRule: FallbackSkillMixTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackSkillMixTemplate) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackSkillMixTemplateCodePrefixRule: FallbackSkillMixTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackSkillMixTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackSkillMixTemplateRefillsRangeRule: FallbackSkillMixTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackSkillMixTemplate) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackSkillMixTemplateRegionLengthRule: FallbackSkillMixTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackSkillMixTemplate) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackSkillMixTemplateTimezoneLengthRule: FallbackSkillMixTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackSkillMixTemplate) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback skill mix template.
    final class FallbackSkillMixTemplateValidator {
        var rules: [any FallbackSkillMixTemplateRule]

        init(rules: [any FallbackSkillMixTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackSkillMixTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackSkillMixTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackSkillMixTemplate]) -> [String: [String]] {
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

    static func defaultFallbackSkillMixTemplateValidator() -> FallbackSkillMixTemplateValidator {
        return FallbackSkillMixTemplateValidator(
            rules: [
                FallbackSkillMixTemplateDiscountRangeRule(min: 1.9, max: 3690.3),
                FallbackSkillMixTemplateVersionRangeRule(min: 32, max: 120),
                FallbackSkillMixTemplateCodePrefixRule(prefix: "OPS"),
                FallbackSkillMixTemplateRefillsRangeRule(min: 32, max: 120),
                FallbackSkillMixTemplateRegionLengthRule(maxLength: 32),
                FallbackSkillMixTemplateTimezoneLengthRule(maxLength: 3600),
            ]
        )
    }
}
