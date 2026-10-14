import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix draft must pass. Check returns its problems, or none.
    protocol SkillMixDraftRule {
        func check(_ item: SkillMixDraft) -> [String]
    }

    final class SkillMixDraftCostRangeRule: SkillMixDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixDraft) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixDraftWindowDaysRangeRule: SkillMixDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixDraft) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixDraftArchivedGuardRule: SkillMixDraftRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SkillMixDraft) -> [String] {
            if item.archived && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix draft.
    final class SkillMixDraftValidator {
        var rules: [any SkillMixDraftRule]

        init(rules: [any SkillMixDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixDraft]) -> [String: [String]] {
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

    static func defaultSkillMixDraftValidator() -> SkillMixDraftValidator {
        return SkillMixDraftValidator(
            rules: [
                SkillMixDraftCostRangeRule(min: 3.8, max: 4010.1),
                SkillMixDraftWindowDaysRangeRule(min: 32, max: 80),
                SkillMixDraftArchivedGuardRule(limit: 80),
            ]
        )
    }
}
