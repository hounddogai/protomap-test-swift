import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped skill mix cycle must pass. Check returns its problems, or none.
    protocol CappedSkillMixCycleRule {
        func check(_ item: CappedSkillMixCycle) -> [String]
    }

    final class CappedSkillMixCycleUnitLengthRule: CappedSkillMixCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSkillMixCycle) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSkillMixCycleCodeLengthRule: CappedSkillMixCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSkillMixCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSkillMixCycleRequiredUnitRule: CappedSkillMixCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedSkillMixCycle) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedSkillMixCycleRequiredTitleRule: CappedSkillMixCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedSkillMixCycle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped skill mix cycle.
    final class CappedSkillMixCycleValidator {
        var rules: [any CappedSkillMixCycleRule]

        init(rules: [any CappedSkillMixCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedSkillMixCycle) -> [String] {
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

        func requireValid(_ item: CappedSkillMixCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedSkillMixCycle]) -> [String: [String]] {
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

    static func defaultCappedSkillMixCycleValidator() -> CappedSkillMixCycleValidator {
        return CappedSkillMixCycleValidator(
            rules: [
                CappedSkillMixCycleUnitLengthRule(maxLength: 120),
                CappedSkillMixCycleCodeLengthRule(maxLength: 64),
                CappedSkillMixCycleRequiredUnitRule(message: "capped skill mix cycle needs an entry"),
                CappedSkillMixCycleRequiredTitleRule(message: "capped skill mix cycle needs an entry"),
            ]
        )
    }
}
