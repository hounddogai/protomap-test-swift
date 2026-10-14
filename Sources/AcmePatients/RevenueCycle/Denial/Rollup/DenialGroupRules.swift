import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial group must pass. Check returns its problems, or none.
    protocol DenialGroupRule {
        func check(_ item: DenialGroup) -> [String]
    }

    final class DenialGroupTagsLimitRule: DenialGroupRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: DenialGroup) -> [String] {
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

    final class DenialGroupCodePrefixRule: DenialGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DenialGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DenialGroupRequiredTitleRule: DenialGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialGroupCostRangeRule: DenialGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialGroup) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DenialGroupTimezoneLengthRule: DenialGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialGroup) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial group.
    final class DenialGroupValidator {
        var rules: [any DenialGroupRule]

        init(rules: [any DenialGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialGroup]) -> [String: [String]] {
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

    static func defaultDenialGroupValidator() -> DenialGroupValidator {
        return DenialGroupValidator(
            rules: [
                DenialGroupTagsLimitRule(maxCount: 120, banned: ["lenient", "batched"]),
                DenialGroupCodePrefixRule(prefix: "X"),
                DenialGroupRequiredTitleRule(message: "denial group needs an entry"),
                DenialGroupCostRangeRule(min: 2.2, max: 1193.8),
                DenialGroupTimezoneLengthRule(maxLength: 32),
            ]
        )
    }
}
