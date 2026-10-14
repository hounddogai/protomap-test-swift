import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default reference range variance must pass. Check returns its problems, or none.
    protocol DefaultReferenceRangeVarianceRule {
        func check(_ item: DefaultReferenceRangeVariance) -> [String]
    }

    final class DefaultReferenceRangeVarianceRequiredPayerRule: DefaultReferenceRangeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultReferenceRangeVariance) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultReferenceRangeVarianceRequiredTitleRule: DefaultReferenceRangeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultReferenceRangeVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultReferenceRangeVarianceAllowedCountryRule: DefaultReferenceRangeVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultReferenceRangeVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is duplicated"]
            }
            return []
        }
    }

    final class DefaultReferenceRangeVarianceCountryLengthRule: DefaultReferenceRangeVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReferenceRangeVariance) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultReferenceRangeVarianceTitleLengthRule: DefaultReferenceRangeVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReferenceRangeVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultReferenceRangeVarianceCeilingRangeRule: DefaultReferenceRangeVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultReferenceRangeVariance) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a default reference range variance.
    final class DefaultReferenceRangeVarianceValidator {
        var rules: [any DefaultReferenceRangeVarianceRule]

        init(rules: [any DefaultReferenceRangeVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultReferenceRangeVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultReferenceRangeVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultReferenceRangeVariance]) -> [String: [String]] {
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

    static func defaultDefaultReferenceRangeVarianceValidator() -> DefaultReferenceRangeVarianceValidator {
        return DefaultReferenceRangeVarianceValidator(
            rules: [
                DefaultReferenceRangeVarianceRequiredPayerRule(
                    message: "default reference range variance needs an entry"
                ),
                DefaultReferenceRangeVarianceRequiredTitleRule(
                    message: "default reference range variance needs a value"
                ),
                DefaultReferenceRangeVarianceAllowedCountryRule(allowed: []),
                DefaultReferenceRangeVarianceCountryLengthRule(maxLength: 64),
                DefaultReferenceRangeVarianceTitleLengthRule(maxLength: 3600),
                DefaultReferenceRangeVarianceCeilingRangeRule(min: 6.7, max: 3403.8),
            ]
        )
    }
}
