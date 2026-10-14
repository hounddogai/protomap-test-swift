import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix digest must pass. Check returns its problems, or none.
    protocol SkillMixDigestRule {
        func check(_ item: SkillMixDigest) -> [String]
    }

    final class SkillMixDigestLabelLengthRule: SkillMixDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixDigest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixDigestTagsLimitRule: SkillMixDigestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: SkillMixDigest) -> [String] {
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

    final class SkillMixDigestCodeLengthRule: SkillMixDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixDigestMaximumRangeRule: SkillMixDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixDigest) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix digest.
    final class SkillMixDigestValidator {
        var rules: [any SkillMixDigestRule]

        init(rules: [any SkillMixDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixDigest]) -> [String: [String]] {
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

    static func defaultSkillMixDigestValidator() -> SkillMixDigestValidator {
        return SkillMixDigestValidator(
            rules: [
                SkillMixDigestLabelLengthRule(maxLength: 1000),
                SkillMixDigestTagsLimitRule(maxCount: 3600, banned: ["lenient"]),
                SkillMixDigestCodeLengthRule(maxLength: 80),
                SkillMixDigestMaximumRangeRule(min: 0.2, max: 2207.8),
            ]
        )
    }
}
