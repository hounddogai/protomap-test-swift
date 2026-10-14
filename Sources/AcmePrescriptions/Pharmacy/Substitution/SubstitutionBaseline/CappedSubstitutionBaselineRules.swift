import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped substitution baseline must pass. Check returns its problems, or none.
    protocol CappedSubstitutionBaselineRule {
        func check(_ item: CappedSubstitutionBaseline) -> [String]
    }

    final class CappedSubstitutionBaselineRequiredCountryRule: CappedSubstitutionBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedSubstitutionBaseline) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedSubstitutionBaselineRequiredPhoneRule: CappedSubstitutionBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedSubstitutionBaseline) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedSubstitutionBaselineCodePrefixRule: CappedSubstitutionBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedSubstitutionBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedSubstitutionBaselineRequiredNameRule: CappedSubstitutionBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedSubstitutionBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped substitution baseline.
    final class CappedSubstitutionBaselineValidator {
        var rules: [any CappedSubstitutionBaselineRule]

        init(rules: [any CappedSubstitutionBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedSubstitutionBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedSubstitutionBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedSubstitutionBaseline]) -> [String: [String]] {
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

    static func defaultCappedSubstitutionBaselineValidator() -> CappedSubstitutionBaselineValidator {
        return CappedSubstitutionBaselineValidator(
            rules: [
                CappedSubstitutionBaselineRequiredCountryRule(message: "capped substitution baseline needs a value"),
                CappedSubstitutionBaselineRequiredPhoneRule(message: "capped substitution baseline needs this field"),
                CappedSubstitutionBaselineCodePrefixRule(prefix: "REF"),
                CappedSubstitutionBaselineRequiredNameRule(message: "capped substitution baseline needs an entry"),
            ]
        )
    }
}
