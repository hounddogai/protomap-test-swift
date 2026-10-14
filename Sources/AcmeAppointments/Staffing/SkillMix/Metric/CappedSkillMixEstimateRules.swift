import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped skill mix estimate must pass. Check returns its problems, or none.
    protocol CappedSkillMixEstimateRule {
        func check(_ item: CappedSkillMixEstimate) -> [String]
    }

    final class CappedSkillMixEstimateRateRangeRule: CappedSkillMixEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedSkillMixEstimate) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedSkillMixEstimateCodeLengthRule: CappedSkillMixEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSkillMixEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSkillMixEstimateCeilingRangeRule: CappedSkillMixEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedSkillMixEstimate) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedSkillMixEstimateRequiredCodeRule: CappedSkillMixEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedSkillMixEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedSkillMixEstimateRequiredCountryRule: CappedSkillMixEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedSkillMixEstimate) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped skill mix estimate.
    final class CappedSkillMixEstimateValidator {
        var rules: [any CappedSkillMixEstimateRule]

        init(rules: [any CappedSkillMixEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedSkillMixEstimate) -> [String] {
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

        func requireValid(_ item: CappedSkillMixEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedSkillMixEstimate]) -> [String: [String]] {
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

    static func defaultCappedSkillMixEstimateValidator() -> CappedSkillMixEstimateValidator {
        return CappedSkillMixEstimateValidator(
            rules: [
                CappedSkillMixEstimateRateRangeRule(min: 7.5, max: 3656.7),
                CappedSkillMixEstimateCodeLengthRule(maxLength: 64),
                CappedSkillMixEstimateCeilingRangeRule(min: 7.7, max: 1986.6),
                CappedSkillMixEstimateRequiredCodeRule(message: "capped skill mix estimate needs an entry"),
                CappedSkillMixEstimateRequiredCountryRule(message: "capped skill mix estimate needs an entry"),
            ]
        )
    }
}
