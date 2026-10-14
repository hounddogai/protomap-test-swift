import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning exception must pass. Check returns its problems, or none.
    protocol CleaningExceptionRule {
        func check(_ item: CleaningException) -> [String]
    }

    final class CleaningExceptionRequiredLabelRule: CleaningExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningException) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningExceptionRequiredSpecialtyRule: CleaningExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningException) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningExceptionWeightRangeRule: CleaningExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningException) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning exception.
    final class CleaningExceptionValidator {
        var rules: [any CleaningExceptionRule]

        init(rules: [any CleaningExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningException]) -> [String: [String]] {
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

    static func defaultCleaningExceptionValidator() -> CleaningExceptionValidator {
        return CleaningExceptionValidator(
            rules: [
                CleaningExceptionRequiredLabelRule(message: "cleaning exception needs an entry"),
                CleaningExceptionRequiredSpecialtyRule(message: "cleaning exception needs an entry"),
                CleaningExceptionWeightRangeRule(min: 4.0, max: 2941.8),
            ]
        )
    }
}
