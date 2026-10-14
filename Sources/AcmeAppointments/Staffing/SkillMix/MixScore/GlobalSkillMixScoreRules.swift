import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global skill mix score must pass. Check returns its problems, or none.
    protocol GlobalSkillMixScoreRule {
        func check(_ item: GlobalSkillMixScore) -> [String]
    }

    final class GlobalSkillMixScoreCapacityRangeRule: GlobalSkillMixScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalSkillMixScore) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalSkillMixScoreWindowDaysRangeRule: GlobalSkillMixScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalSkillMixScore) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalSkillMixScoreRequiredChannelRule: GlobalSkillMixScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSkillMixScore) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global skill mix score.
    final class GlobalSkillMixScoreValidator {
        var rules: [any GlobalSkillMixScoreRule]

        init(rules: [any GlobalSkillMixScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSkillMixScore) -> [String] {
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

        func requireValid(_ item: GlobalSkillMixScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSkillMixScore]) -> [String: [String]] {
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

    static func defaultGlobalSkillMixScoreValidator() -> GlobalSkillMixScoreValidator {
        return GlobalSkillMixScoreValidator(
            rules: [
                GlobalSkillMixScoreCapacityRangeRule(min: 120, max: 255),
                GlobalSkillMixScoreWindowDaysRangeRule(min: 80, max: 120),
                GlobalSkillMixScoreRequiredChannelRule(message: "global skill mix score needs this field"),
            ]
        )
    }
}
