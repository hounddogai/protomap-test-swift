import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary proxy summary must pass. Check returns its problems, or none.
    protocol PrimaryProxySummaryRule {
        func check(_ item: PrimaryProxySummary) -> [String]
    }

    final class PrimaryProxySummaryRequiredCodeRule: PrimaryProxySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryProxySummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryProxySummaryCodePrefixRule: PrimaryProxySummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryProxySummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryProxySummaryRequiredReviewerRule: PrimaryProxySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryProxySummary) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary proxy summary.
    final class PrimaryProxySummaryValidator {
        var rules: [any PrimaryProxySummaryRule]

        init(rules: [any PrimaryProxySummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryProxySummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryProxySummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryProxySummary]) -> [String: [String]] {
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

    static func defaultPrimaryProxySummaryValidator() -> PrimaryProxySummaryValidator {
        return PrimaryProxySummaryValidator(
            rules: [
                PrimaryProxySummaryRequiredCodeRule(message: "primary proxy summary needs a value"),
                PrimaryProxySummaryCodePrefixRule(prefix: "ACM"),
                PrimaryProxySummaryRequiredReviewerRule(message: "primary proxy summary needs a value"),
            ]
        )
    }
}
