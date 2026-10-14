import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive statement threshold must pass. Check returns its problems, or none.
    protocol AdaptiveStatementThresholdRule {
        func check(_ item: AdaptiveStatementThreshold) -> [String]
    }

    final class AdaptiveStatementThresholdRequiredTimezoneRule: AdaptiveStatementThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveStatementThreshold) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveStatementThresholdTagsLimitRule: AdaptiveStatementThresholdRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: AdaptiveStatementThreshold) -> [String] {
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

    final class AdaptiveStatementThresholdCodeLengthRule: AdaptiveStatementThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveStatementThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveStatementThresholdRequiredLabelRule: AdaptiveStatementThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveStatementThreshold) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive statement threshold.
    final class AdaptiveStatementThresholdValidator {
        var rules: [any AdaptiveStatementThresholdRule]

        init(rules: [any AdaptiveStatementThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveStatementThreshold) -> [String] {
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

        func requireValid(_ item: AdaptiveStatementThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveStatementThreshold]) -> [String: [String]] {
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

    static func defaultAdaptiveStatementThresholdValidator() -> AdaptiveStatementThresholdValidator {
        return AdaptiveStatementThresholdValidator(
            rules: [
                AdaptiveStatementThresholdRequiredTimezoneRule(
                    message: "adaptive statement threshold needs this field"
                ),
                AdaptiveStatementThresholdTagsLimitRule(maxCount: 32, banned: ["strict", "scheduled"]),
                AdaptiveStatementThresholdCodeLengthRule(maxLength: 120),
                AdaptiveStatementThresholdRequiredLabelRule(message: "adaptive statement threshold needs this field"),
            ]
        )
    }
}
