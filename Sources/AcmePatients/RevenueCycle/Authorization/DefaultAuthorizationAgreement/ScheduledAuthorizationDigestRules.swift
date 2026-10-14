import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a scheduled authorization digest must pass. Check returns its problems, or none.
    protocol ScheduledAuthorizationDigestRule {
        func check(_ item: ScheduledAuthorizationDigest) -> [String]
    }

    final class ScheduledAuthorizationDigestRequiredTitleRule: ScheduledAuthorizationDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAuthorizationDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAuthorizationDigestCodeLengthRule: ScheduledAuthorizationDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAuthorizationDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledAuthorizationDigestPriorityRangeRule: ScheduledAuthorizationDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledAuthorizationDigest) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledAuthorizationDigestAmountRangeRule: ScheduledAuthorizationDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledAuthorizationDigest) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledAuthorizationDigestRequiredDescriptionRule: ScheduledAuthorizationDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAuthorizationDigest) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAuthorizationDigestAllowedSourceRule: ScheduledAuthorizationDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledAuthorizationDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled authorization digest.
    final class ScheduledAuthorizationDigestValidator {
        var rules: [any ScheduledAuthorizationDigestRule]

        init(rules: [any ScheduledAuthorizationDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAuthorizationDigest) -> [String] {
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

        func requireValid(_ item: ScheduledAuthorizationDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAuthorizationDigest]) -> [String: [String]] {
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

    static func defaultScheduledAuthorizationDigestValidator() -> ScheduledAuthorizationDigestValidator {
        return ScheduledAuthorizationDigestValidator(
            rules: [
                ScheduledAuthorizationDigestRequiredTitleRule(message: "scheduled authorization digest needs a value"),
                ScheduledAuthorizationDigestCodeLengthRule(maxLength: 3600),
                ScheduledAuthorizationDigestPriorityRangeRule(min: 64, max: 120),
                ScheduledAuthorizationDigestAmountRangeRule(min: 9.5, max: 3437.0),
                ScheduledAuthorizationDigestRequiredDescriptionRule(
                    message: "scheduled authorization digest needs an entry"
                ),
                ScheduledAuthorizationDigestAllowedSourceRule(allowed: ["lenient", "global", "default"]),
            ]
        )
    }
}
