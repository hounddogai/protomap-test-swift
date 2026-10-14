import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional skill mix score must pass. Check returns its problems, or none.
    protocol RegionalSkillMixScoreRule {
        func check(_ item: RegionalSkillMixScore) -> [String]
    }

    final class RegionalSkillMixScoreRevisionRangeRule: RegionalSkillMixScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSkillMixScore) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalSkillMixScoreWeightRangeRule: RegionalSkillMixScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSkillMixScore) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalSkillMixScoreRequiredSpecialtyRule: RegionalSkillMixScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSkillMixScore) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalSkillMixScoreRequiredRegionRule: RegionalSkillMixScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSkillMixScore) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional skill mix score.
    final class RegionalSkillMixScoreValidator {
        var rules: [any RegionalSkillMixScoreRule]

        init(rules: [any RegionalSkillMixScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSkillMixScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalSkillMixScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSkillMixScore]) -> [String: [String]] {
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

    static func defaultRegionalSkillMixScoreValidator() -> RegionalSkillMixScoreValidator {
        return RegionalSkillMixScoreValidator(
            rules: [
                RegionalSkillMixScoreRevisionRangeRule(min: 80, max: 120),
                RegionalSkillMixScoreWeightRangeRule(min: 0.1, max: 558.1),
                RegionalSkillMixScoreRequiredSpecialtyRule(message: "regional skill mix score needs an entry"),
                RegionalSkillMixScoreRequiredRegionRule(message: "regional skill mix score needs this field"),
            ]
        )
    }
}
