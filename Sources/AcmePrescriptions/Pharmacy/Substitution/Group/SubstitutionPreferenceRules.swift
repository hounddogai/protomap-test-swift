import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution preference must pass. Check returns its problems, or none.
    protocol SubstitutionPreferenceRule {
        func check(_ item: SubstitutionPreference) -> [String]
    }

    final class SubstitutionPreferenceCodePrefixRule: SubstitutionPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SubstitutionPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SubstitutionPreferenceRequiredChecksumRule: SubstitutionPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionPreference) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionPreferenceWeightRangeRule: SubstitutionPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionPreference) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a substitution preference.
    final class SubstitutionPreferenceValidator {
        var rules: [any SubstitutionPreferenceRule]

        init(rules: [any SubstitutionPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionPreference) -> [String] {
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

        func requireValid(_ item: SubstitutionPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionPreference]) -> [String: [String]] {
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

    static func defaultSubstitutionPreferenceValidator() -> SubstitutionPreferenceValidator {
        return SubstitutionPreferenceValidator(
            rules: [
                SubstitutionPreferenceCodePrefixRule(prefix: "OPS"),
                SubstitutionPreferenceRequiredChecksumRule(message: "substitution preference needs an entry"),
                SubstitutionPreferenceWeightRangeRule(min: 1.2, max: 565.6),
            ]
        )
    }
}
