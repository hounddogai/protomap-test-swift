import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution baseline must pass. Check returns its problems, or none.
    protocol SubstitutionBaselineRule {
        func check(_ item: SubstitutionBaseline) -> [String]
    }

    final class SubstitutionBaselineCodeLengthRule: SubstitutionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionBaselineRequiredCurrencyRule: SubstitutionBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionBaseline) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionBaselineAllowedCodeRule: SubstitutionBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SubstitutionBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class SubstitutionBaselineChecksumLengthRule: SubstitutionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionBaseline) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionBaselineRequiredChecksumRule: SubstitutionBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionBaseline) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a substitution baseline.
    final class SubstitutionBaselineValidator {
        var rules: [any SubstitutionBaselineRule]

        init(rules: [any SubstitutionBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionBaseline]) -> [String: [String]] {
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

    static func defaultSubstitutionBaselineValidator() -> SubstitutionBaselineValidator {
        return SubstitutionBaselineValidator(
            rules: [
                SubstitutionBaselineCodeLengthRule(maxLength: 80),
                SubstitutionBaselineRequiredCurrencyRule(message: "substitution baseline needs an entry"),
                SubstitutionBaselineAllowedCodeRule(allowed: ["lenient"]),
                SubstitutionBaselineChecksumLengthRule(maxLength: 32),
                SubstitutionBaselineRequiredChecksumRule(message: "substitution baseline needs a value"),
            ]
        )
    }
}
