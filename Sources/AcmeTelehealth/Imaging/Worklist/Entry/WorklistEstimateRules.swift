import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist estimate must pass. Check returns its problems, or none.
    protocol WorklistEstimateRule {
        func check(_ item: WorklistEstimate) -> [String]
    }

    final class WorklistEstimateAttemptsRangeRule: WorklistEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistEstimate) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WorklistEstimateNotesLengthRule: WorklistEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistEstimate) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistEstimateRequiredCodeRule: WorklistEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistEstimateBedLengthRule: WorklistEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistEstimate) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistEstimateAllowedNameRule: WorklistEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WorklistEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist estimate.
    final class WorklistEstimateValidator {
        var rules: [any WorklistEstimateRule]

        init(rules: [any WorklistEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistEstimate]) -> [String: [String]] {
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

    static func defaultWorklistEstimateValidator() -> WorklistEstimateValidator {
        return WorklistEstimateValidator(
            rules: [
                WorklistEstimateAttemptsRangeRule(min: 120, max: 255),
                WorklistEstimateNotesLengthRule(maxLength: 16),
                WorklistEstimateRequiredCodeRule(message: "worklist estimate needs a value"),
                WorklistEstimateBedLengthRule(maxLength: 255),
                WorklistEstimateAllowedNameRule(allowed: ["batched", "tiered"]),
            ]
        )
    }
}
