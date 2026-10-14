import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution entry must pass. Check returns its problems, or none.
    protocol SubstitutionEntryRule {
        func check(_ item: SubstitutionEntry) -> [String]
    }

    final class SubstitutionEntryRequiredRegionRule: SubstitutionEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionEntry) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionEntryRequiredCodeRule: SubstitutionEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionEntryMinimumRangeRule: SubstitutionEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionEntry) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SubstitutionEntryRequiredReviewerRule: SubstitutionEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionEntry) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionEntryWeightRangeRule: SubstitutionEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionEntry) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution entry.
    final class SubstitutionEntryValidator {
        var rules: [any SubstitutionEntryRule]

        init(rules: [any SubstitutionEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionEntry) -> [String] {
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

        func requireValid(_ item: SubstitutionEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionEntry]) -> [String: [String]] {
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

    static func defaultSubstitutionEntryValidator() -> SubstitutionEntryValidator {
        return SubstitutionEntryValidator(
            rules: [
                SubstitutionEntryRequiredRegionRule(message: "substitution entry needs a value"),
                SubstitutionEntryRequiredCodeRule(message: "substitution entry needs a value"),
                SubstitutionEntryMinimumRangeRule(min: 0.2, max: 3366.3),
                SubstitutionEntryRequiredReviewerRule(message: "substitution entry needs a value"),
                SubstitutionEntryWeightRangeRule(min: 6.5, max: 1954.2),
            ]
        )
    }
}
