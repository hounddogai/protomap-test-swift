import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted substitution digest must pass. Check returns its problems, or none.
    protocol WeightedSubstitutionDigestRule {
        func check(_ item: WeightedSubstitutionDigest) -> [String]
    }

    final class WeightedSubstitutionDigestRequiredLabelRule: WeightedSubstitutionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSubstitutionDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSubstitutionDigestCodePrefixRule: WeightedSubstitutionDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedSubstitutionDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedSubstitutionDigestRequiredNotesRule: WeightedSubstitutionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSubstitutionDigest) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSubstitutionDigestBudgetRangeRule: WeightedSubstitutionDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedSubstitutionDigest) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedSubstitutionDigestRequiredCodeRule: WeightedSubstitutionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSubstitutionDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted substitution digest.
    final class WeightedSubstitutionDigestValidator {
        var rules: [any WeightedSubstitutionDigestRule]

        init(rules: [any WeightedSubstitutionDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSubstitutionDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedSubstitutionDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSubstitutionDigest]) -> [String: [String]] {
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

    static func defaultWeightedSubstitutionDigestValidator() -> WeightedSubstitutionDigestValidator {
        return WeightedSubstitutionDigestValidator(
            rules: [
                WeightedSubstitutionDigestRequiredLabelRule(message: "weighted substitution digest needs a value"),
                WeightedSubstitutionDigestCodePrefixRule(prefix: "OPS"),
                WeightedSubstitutionDigestRequiredNotesRule(message: "weighted substitution digest needs this field"),
                WeightedSubstitutionDigestBudgetRangeRule(min: 4.6, max: 1032.8),
                WeightedSubstitutionDigestRequiredCodeRule(message: "weighted substitution digest needs an entry"),
            ]
        )
    }
}
