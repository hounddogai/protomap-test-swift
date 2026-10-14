import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive discharge plan baseline must pass. Check returns its problems, or none.
    protocol AdaptiveDischargePlanBaselineRule {
        func check(_ item: AdaptiveDischargePlanBaseline) -> [String]
    }

    final class AdaptiveDischargePlanBaselineRequiredCodeRule: AdaptiveDischargePlanBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDischargePlanBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveDischargePlanBaselineAllowedCountryRule: AdaptiveDischargePlanBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveDischargePlanBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is not allowed"]
            }
            return []
        }
    }

    final class AdaptiveDischargePlanBaselineRequiredNameRule: AdaptiveDischargePlanBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDischargePlanBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveDischargePlanBaselineCodePrefixRule: AdaptiveDischargePlanBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveDischargePlanBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveDischargePlanBaselineCountryLengthRule: AdaptiveDischargePlanBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDischargePlanBaseline) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive discharge plan baseline.
    final class AdaptiveDischargePlanBaselineValidator {
        var rules: [any AdaptiveDischargePlanBaselineRule]

        init(rules: [any AdaptiveDischargePlanBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveDischargePlanBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveDischargePlanBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveDischargePlanBaseline]) -> [String: [String]] {
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

    static func defaultAdaptiveDischargePlanBaselineValidator() -> AdaptiveDischargePlanBaselineValidator {
        return AdaptiveDischargePlanBaselineValidator(
            rules: [
                AdaptiveDischargePlanBaselineRequiredCodeRule(
                    message: "adaptive discharge plan baseline needs an entry"
                ),
                AdaptiveDischargePlanBaselineAllowedCountryRule(allowed: ["weighted", "manual", "rolling"]),
                AdaptiveDischargePlanBaselineRequiredNameRule(
                    message: "adaptive discharge plan baseline needs an entry"
                ),
                AdaptiveDischargePlanBaselineCodePrefixRule(prefix: "ACM"),
                AdaptiveDischargePlanBaselineCountryLengthRule(maxLength: 64),
            ]
        )
    }
}
