import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary recall policy must pass. Check returns its problems, or none.
    protocol PrimaryRecallPolicyRule {
        func check(_ item: PrimaryRecallPolicy) -> [String]
    }

    final class PrimaryRecallPolicyAllowedTimezoneRule: PrimaryRecallPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryRecallPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is unknown"]
            }
            return []
        }
    }

    final class PrimaryRecallPolicyRequiredCategoryRule: PrimaryRecallPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRecallPolicy) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRecallPolicyTimezoneLengthRule: PrimaryRecallPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRecallPolicy) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRecallPolicyCodeLengthRule: PrimaryRecallPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRecallPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRecallPolicyCodePrefixRule: PrimaryRecallPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryRecallPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryRecallPolicyCategoryLengthRule: PrimaryRecallPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRecallPolicy) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary recall policy.
    final class PrimaryRecallPolicyValidator {
        var rules: [any PrimaryRecallPolicyRule]

        init(rules: [any PrimaryRecallPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryRecallPolicy) -> [String] {
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

        func requireValid(_ item: PrimaryRecallPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryRecallPolicy]) -> [String: [String]] {
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

    static func defaultPrimaryRecallPolicyValidator() -> PrimaryRecallPolicyValidator {
        return PrimaryRecallPolicyValidator(
            rules: [
                PrimaryRecallPolicyAllowedTimezoneRule(allowed: ["regional"]),
                PrimaryRecallPolicyRequiredCategoryRule(message: "primary recall policy needs this field"),
                PrimaryRecallPolicyTimezoneLengthRule(maxLength: 1000),
                PrimaryRecallPolicyCodeLengthRule(maxLength: 16),
                PrimaryRecallPolicyCodePrefixRule(prefix: "X"),
                PrimaryRecallPolicyCategoryLengthRule(maxLength: 32),
            ]
        )
    }
}
