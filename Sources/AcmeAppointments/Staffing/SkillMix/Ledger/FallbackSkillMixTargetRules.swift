import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback skill mix target must pass. Check returns its problems, or none.
    protocol FallbackSkillMixTargetRule {
        func check(_ item: FallbackSkillMixTarget) -> [String]
    }

    final class FallbackSkillMixTargetTitleLengthRule: FallbackSkillMixTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackSkillMixTarget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackSkillMixTargetMaximumRangeRule: FallbackSkillMixTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackSkillMixTarget) -> [String] {
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

    final class FallbackSkillMixTargetAcuityRangeRule: FallbackSkillMixTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackSkillMixTarget) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackSkillMixTargetTagsLimitRule: FallbackSkillMixTargetRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: FallbackSkillMixTarget) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    /// Runs every rule of a fallback skill mix target.
    final class FallbackSkillMixTargetValidator {
        var rules: [any FallbackSkillMixTargetRule]

        init(rules: [any FallbackSkillMixTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackSkillMixTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackSkillMixTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackSkillMixTarget]) -> [String: [String]] {
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

    static func defaultFallbackSkillMixTargetValidator() -> FallbackSkillMixTargetValidator {
        return FallbackSkillMixTargetValidator(
            rules: [
                FallbackSkillMixTargetTitleLengthRule(maxLength: 16),
                FallbackSkillMixTargetMaximumRangeRule(min: 4.5, max: 4511.7),
                FallbackSkillMixTargetAcuityRangeRule(min: 16, max: 32),
                FallbackSkillMixTargetTagsLimitRule(maxCount: 86400, banned: ["seasonal", "weighted", "rolling"]),
            ]
        )
    }
}
