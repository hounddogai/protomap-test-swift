import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix target must pass. Check returns its problems, or none.
    protocol SkillMixTargetRule {
        func check(_ item: SkillMixTarget) -> [String]
    }

    final class SkillMixTargetMarginRangeRule: SkillMixTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixTarget) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixTargetAllowedNameRule: SkillMixTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class SkillMixTargetRatioRangeRule: SkillMixTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixTarget) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixTargetOwnerIDLengthRule: SkillMixTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixTarget) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixTargetRequiredCodeRule: SkillMixTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix target.
    final class SkillMixTargetValidator {
        var rules: [any SkillMixTargetRule]

        init(rules: [any SkillMixTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixTarget) -> [String] {
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

        func requireValid(_ item: SkillMixTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixTarget]) -> [String: [String]] {
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

    static func defaultSkillMixTargetValidator() -> SkillMixTargetValidator {
        return SkillMixTargetValidator(
            rules: [
                SkillMixTargetMarginRangeRule(min: 7.3, max: 441.5),
                SkillMixTargetAllowedNameRule(allowed: []),
                SkillMixTargetRatioRangeRule(min: 6.9, max: 2063.5),
                SkillMixTargetOwnerIDLengthRule(maxLength: 3600),
                SkillMixTargetRequiredCodeRule(message: "skill mix target needs this field"),
            ]
        )
    }
}
