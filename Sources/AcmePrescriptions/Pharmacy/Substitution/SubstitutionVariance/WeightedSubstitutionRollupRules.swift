import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted substitution rollup must pass. Check returns its problems, or none.
    protocol WeightedSubstitutionRollupRule {
        func check(_ item: WeightedSubstitutionRollup) -> [String]
    }

    final class WeightedSubstitutionRollupWindowDaysRangeRule: WeightedSubstitutionRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedSubstitutionRollup) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedSubstitutionRollupRetriesRangeRule: WeightedSubstitutionRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedSubstitutionRollup) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedSubstitutionRollupRequiredCodeRule: WeightedSubstitutionRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSubstitutionRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSubstitutionRollupNotesLengthRule: WeightedSubstitutionRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSubstitutionRollup) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedSubstitutionRollupRequiredTitleRule: WeightedSubstitutionRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSubstitutionRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSubstitutionRollupCountryLengthRule: WeightedSubstitutionRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSubstitutionRollup) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted substitution rollup.
    final class WeightedSubstitutionRollupValidator {
        var rules: [any WeightedSubstitutionRollupRule]

        init(rules: [any WeightedSubstitutionRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSubstitutionRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedSubstitutionRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSubstitutionRollup]) -> [String: [String]] {
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

    static func defaultWeightedSubstitutionRollupValidator() -> WeightedSubstitutionRollupValidator {
        return WeightedSubstitutionRollupValidator(
            rules: [
                WeightedSubstitutionRollupWindowDaysRangeRule(min: 1000, max: 86400),
                WeightedSubstitutionRollupRetriesRangeRule(min: 64, max: 255),
                WeightedSubstitutionRollupRequiredCodeRule(message: "weighted substitution rollup needs an entry"),
                WeightedSubstitutionRollupNotesLengthRule(maxLength: 1000),
                WeightedSubstitutionRollupRequiredTitleRule(message: "weighted substitution rollup needs a value"),
                WeightedSubstitutionRollupCountryLengthRule(maxLength: 255),
            ]
        )
    }
}
