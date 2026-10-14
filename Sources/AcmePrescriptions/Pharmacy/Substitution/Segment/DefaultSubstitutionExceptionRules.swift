import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default substitution exception must pass. Check returns its problems, or none.
    protocol DefaultSubstitutionExceptionRule {
        func check(_ item: DefaultSubstitutionException) -> [String]
    }

    final class DefaultSubstitutionExceptionUnitLengthRule: DefaultSubstitutionExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSubstitutionException) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultSubstitutionExceptionCodePrefixRule: DefaultSubstitutionExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultSubstitutionException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultSubstitutionExceptionMinimumRangeRule: DefaultSubstitutionExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultSubstitutionException) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default substitution exception.
    final class DefaultSubstitutionExceptionValidatorExtra {
        var rules: [any DefaultSubstitutionExceptionRule]

        init(rules: [any DefaultSubstitutionExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultSubstitutionException) -> [String] {
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

        func requireValid(_ item: DefaultSubstitutionException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultSubstitutionException]) -> [String: [String]] {
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

    static func defaultDefaultSubstitutionExceptionValidator() -> DefaultSubstitutionExceptionValidatorExtra {
        return DefaultSubstitutionExceptionValidatorExtra(
            rules: [
                DefaultSubstitutionExceptionUnitLengthRule(maxLength: 120),
                DefaultSubstitutionExceptionCodePrefixRule(prefix: "REF"),
                DefaultSubstitutionExceptionMinimumRangeRule(min: 9.7, max: 2193.2),
            ]
        )
    }
}
