import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary skill mix score must pass. Check returns its problems, or none.
    protocol PrimarySkillMixScoreRule {
        func check(_ item: PrimarySkillMixScore) -> [String]
    }

    final class PrimarySkillMixScoreRequiredCodeRule: PrimarySkillMixScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySkillMixScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySkillMixScoreAllowedFacilityRule: PrimarySkillMixScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimarySkillMixScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is below minimum"]
            }
            return []
        }
    }

    final class PrimarySkillMixScoreCeilingRangeRule: PrimarySkillMixScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimarySkillMixScore) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary skill mix score.
    final class PrimarySkillMixScoreValidator {
        var rules: [any PrimarySkillMixScoreRule]

        init(rules: [any PrimarySkillMixScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimarySkillMixScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimarySkillMixScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimarySkillMixScore]) -> [String: [String]] {
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

    static func defaultPrimarySkillMixScoreValidator() -> PrimarySkillMixScoreValidator {
        return PrimarySkillMixScoreValidator(
            rules: [
                PrimarySkillMixScoreRequiredCodeRule(message: "primary skill mix score needs a value"),
                PrimarySkillMixScoreAllowedFacilityRule(allowed: ["pending"]),
                PrimarySkillMixScoreCeilingRangeRule(min: 6.6, max: 1696.4),
            ]
        )
    }
}
