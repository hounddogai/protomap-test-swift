import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional disclosure summary must pass. Check returns its problems, or none.
    protocol RegionalDisclosureSummaryRule {
        func check(_ item: RegionalDisclosureSummary) -> [String]
    }

    final class RegionalDisclosureSummaryLabelLengthRule: RegionalDisclosureSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalDisclosureSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalDisclosureSummaryAllowedCodeRule: RegionalDisclosureSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalDisclosureSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class RegionalDisclosureSummaryRequiredCountryRule: RegionalDisclosureSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDisclosureSummary) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional disclosure summary.
    final class RegionalDisclosureSummaryValidator {
        var rules: [any RegionalDisclosureSummaryRule]

        init(rules: [any RegionalDisclosureSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalDisclosureSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalDisclosureSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalDisclosureSummary]) -> [String: [String]] {
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

    static func defaultRegionalDisclosureSummaryValidator() -> RegionalDisclosureSummaryValidator {
        return RegionalDisclosureSummaryValidator(
            rules: [
                RegionalDisclosureSummaryLabelLengthRule(maxLength: 16),
                RegionalDisclosureSummaryAllowedCodeRule(allowed: ["legacy", "global", "manual"]),
                RegionalDisclosureSummaryRequiredCountryRule(message: "regional disclosure summary needs an entry"),
            ]
        )
    }
}
