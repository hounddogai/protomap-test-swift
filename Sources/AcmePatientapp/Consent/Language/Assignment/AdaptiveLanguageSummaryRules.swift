import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive language summary must pass. Check returns its problems, or none.
    protocol AdaptiveLanguageSummaryRule {
        func check(_ item: AdaptiveLanguageSummary) -> [String]
    }

    final class AdaptiveLanguageSummaryRequiredCodeRule: AdaptiveLanguageSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveLanguageSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveLanguageSummaryStartsAtRangeRule: AdaptiveLanguageSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveLanguageSummary) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveLanguageSummaryDescriptionLengthRule: AdaptiveLanguageSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveLanguageSummary) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveLanguageSummaryAllowedNameRule: AdaptiveLanguageSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveLanguageSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive language summary.
    final class AdaptiveLanguageSummaryValidator {
        var rules: [any AdaptiveLanguageSummaryRule]

        init(rules: [any AdaptiveLanguageSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveLanguageSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveLanguageSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveLanguageSummary]) -> [String: [String]] {
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

    static func defaultAdaptiveLanguageSummaryValidator() -> AdaptiveLanguageSummaryValidator {
        return AdaptiveLanguageSummaryValidator(
            rules: [
                AdaptiveLanguageSummaryRequiredCodeRule(message: "adaptive language summary needs a value"),
                AdaptiveLanguageSummaryStartsAtRangeRule(min: 80, max: 120),
                AdaptiveLanguageSummaryDescriptionLengthRule(maxLength: 86400),
                AdaptiveLanguageSummaryAllowedNameRule(allowed: ["weighted", "adaptive"]),
            ]
        )
    }
}
