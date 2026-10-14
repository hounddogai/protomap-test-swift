import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient cleaning estimate must pass. Check returns its problems, or none.
    protocol LenientCleaningEstimateRule {
        func check(_ item: LenientCleaningEstimate) -> [String]
    }

    final class LenientCleaningEstimateRequiredNameRule: LenientCleaningEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCleaningEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCleaningEstimateRequiredNotesRule: LenientCleaningEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCleaningEstimate) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCleaningEstimateRequiredCodeRule: LenientCleaningEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCleaningEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCleaningEstimateNameLengthRule: LenientCleaningEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCleaningEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCleaningEstimateBudgetRangeRule: LenientCleaningEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCleaningEstimate) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a lenient cleaning estimate.
    final class LenientCleaningEstimateValidator {
        var rules: [any LenientCleaningEstimateRule]

        init(rules: [any LenientCleaningEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCleaningEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientCleaningEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCleaningEstimate]) -> [String: [String]] {
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

    static func defaultLenientCleaningEstimateValidator() -> LenientCleaningEstimateValidator {
        return LenientCleaningEstimateValidator(
            rules: [
                LenientCleaningEstimateRequiredNameRule(message: "lenient cleaning estimate needs an entry"),
                LenientCleaningEstimateRequiredNotesRule(message: "lenient cleaning estimate needs a value"),
                LenientCleaningEstimateRequiredCodeRule(message: "lenient cleaning estimate needs an entry"),
                LenientCleaningEstimateNameLengthRule(maxLength: 1000),
                LenientCleaningEstimateBudgetRangeRule(min: 8.7, max: 1765.7),
            ]
        )
    }
}
