import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix entry must pass. Check returns its problems, or none.
    protocol SkillMixEntryRule {
        func check(_ item: SkillMixEntry) -> [String]
    }

    final class SkillMixEntryAllowedContactEmailRule: SkillMixEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is out of range"]
            }
            return []
        }
    }

    final class SkillMixEntryMaximumRangeRule: SkillMixEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixEntry) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixEntryVisitMinutesRangeRule: SkillMixEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixEntry) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix entry.
    final class SkillMixEntryValidator {
        var rules: [any SkillMixEntryRule]

        init(rules: [any SkillMixEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixEntry]) -> [String: [String]] {
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

    static func defaultSkillMixEntryValidator() -> SkillMixEntryValidator {
        return SkillMixEntryValidator(
            rules: [
                SkillMixEntryAllowedContactEmailRule(allowed: ["strict", "primary", "primary"]),
                SkillMixEntryMaximumRangeRule(min: 6.0, max: 1005.2),
                SkillMixEntryVisitMinutesRangeRule(min: 16, max: 16),
            ]
        )
    }
}
