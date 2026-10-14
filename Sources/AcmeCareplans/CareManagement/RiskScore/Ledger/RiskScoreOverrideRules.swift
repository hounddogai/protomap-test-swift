import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score override must pass. Check returns its problems, or none.
    protocol RiskScoreOverrideRule {
        func check(_ item: RiskScoreOverride) -> [String]
    }

    final class RiskScoreOverrideReviewerLengthRule: RiskScoreOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreOverride) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreOverrideCodePrefixRule: RiskScoreOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreOverrideTagsLimitRule: RiskScoreOverrideRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RiskScoreOverride) -> [String] {
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

    final class RiskScoreOverrideRequiredTitleRule: RiskScoreOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreOverrideRefillsRangeRule: RiskScoreOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreOverride) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RiskScoreOverrideWindowDaysRangeRule: RiskScoreOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreOverride) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score override.
    final class RiskScoreOverrideValidator {
        var rules: [any RiskScoreOverrideRule]

        init(rules: [any RiskScoreOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreOverride) -> [String] {
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

        func requireValid(_ item: RiskScoreOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreOverride]) -> [String: [String]] {
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

    static func defaultRiskScoreOverrideValidator() -> RiskScoreOverrideValidator {
        return RiskScoreOverrideValidator(
            rules: [
                RiskScoreOverrideReviewerLengthRule(maxLength: 86400),
                RiskScoreOverrideCodePrefixRule(prefix: "X"),
                RiskScoreOverrideTagsLimitRule(maxCount: 255, banned: ["fallback"]),
                RiskScoreOverrideRequiredTitleRule(message: "risk score override needs a value"),
                RiskScoreOverrideRefillsRangeRule(min: 64, max: 86400),
                RiskScoreOverrideWindowDaysRangeRule(min: 64, max: 1000),
            ]
        )
    }
}
