import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility rollup must pass. Check returns its problems, or none.
    protocol EligibilityRollupRule {
        func check(_ item: EligibilityRollup) -> [String]
    }

    final class EligibilityRollupNameLengthRule: EligibilityRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityRollupCodeLengthRule: EligibilityRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityRollupCapacityRangeRule: EligibilityRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityRollup) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class EligibilityRollupAllowedCodeRule: EligibilityRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class EligibilityRollupTagsLimitRule: EligibilityRollupRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: EligibilityRollup) -> [String] {
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

    /// Runs every rule of a eligibility rollup.
    final class EligibilityRollupValidator {
        var rules: [any EligibilityRollupRule]

        init(rules: [any EligibilityRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityRollup]) -> [String: [String]] {
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

    static func defaultEligibilityRollupValidator() -> EligibilityRollupValidator {
        return EligibilityRollupValidator(
            rules: [
                EligibilityRollupNameLengthRule(maxLength: 1000),
                EligibilityRollupCodeLengthRule(maxLength: 255),
                EligibilityRollupCapacityRangeRule(min: 80, max: 255),
                EligibilityRollupAllowedCodeRule(allowed: ["global"]),
                EligibilityRollupTagsLimitRule(maxCount: 120, banned: ["capped"]),
            ]
        )
    }
}
