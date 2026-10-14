import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim summary must pass. Check returns its problems, or none.
    protocol ClaimSummaryRule {
        func check(_ item: ClaimSummary) -> [String]
    }

    final class ClaimSummaryRequiredLabelRule: ClaimSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimSummaryCodePrefixRule: ClaimSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClaimSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClaimSummaryTimezoneLengthRule: ClaimSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimSummary) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimSummaryEndsAtRangeRule: ClaimSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimSummary) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a claim summary.
    final class ClaimSummaryValidator {
        var rules: [any ClaimSummaryRule]

        init(rules: [any ClaimSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimSummary) -> [String] {
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

        func requireValid(_ item: ClaimSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimSummary]) -> [String: [String]] {
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

    static func defaultClaimSummaryValidator() -> ClaimSummaryValidator {
        return ClaimSummaryValidator(
            rules: [
                ClaimSummaryRequiredLabelRule(message: "claim summary needs an entry"),
                ClaimSummaryCodePrefixRule(prefix: "ACM"),
                ClaimSummaryTimezoneLengthRule(maxLength: 64),
                ClaimSummaryEndsAtRangeRule(min: 64, max: 80),
            ]
        )
    }
}
