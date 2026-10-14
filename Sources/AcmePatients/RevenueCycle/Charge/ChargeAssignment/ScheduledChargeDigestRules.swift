import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a scheduled charge digest must pass. Check returns its problems, or none.
    protocol ScheduledChargeDigestRule {
        func check(_ item: ScheduledChargeDigest) -> [String]
    }

    final class ScheduledChargeDigestCodePrefixRule: ScheduledChargeDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledChargeDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledChargeDigestCategoryLengthRule: ScheduledChargeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledChargeDigest) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledChargeDigestWindowDaysRangeRule: ScheduledChargeDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledChargeDigest) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledChargeDigestRequiredNameRule: ScheduledChargeDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledChargeDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledChargeDigestNameLengthRule: ScheduledChargeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledChargeDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledChargeDigestAllowedNameRule: ScheduledChargeDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledChargeDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled charge digest.
    final class ScheduledChargeDigestValidator {
        var rules: [any ScheduledChargeDigestRule]

        init(rules: [any ScheduledChargeDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledChargeDigest) -> [String] {
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

        func requireValid(_ item: ScheduledChargeDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledChargeDigest]) -> [String: [String]] {
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

    static func defaultScheduledChargeDigestValidator() -> ScheduledChargeDigestValidator {
        return ScheduledChargeDigestValidator(
            rules: [
                ScheduledChargeDigestCodePrefixRule(prefix: "Q"),
                ScheduledChargeDigestCategoryLengthRule(maxLength: 16),
                ScheduledChargeDigestWindowDaysRangeRule(min: 3600, max: 86400),
                ScheduledChargeDigestRequiredNameRule(message: "scheduled charge digest needs an entry"),
                ScheduledChargeDigestNameLengthRule(maxLength: 86400),
                ScheduledChargeDigestAllowedNameRule(allowed: ["rolling", "scheduled"]),
            ]
        )
    }
}
