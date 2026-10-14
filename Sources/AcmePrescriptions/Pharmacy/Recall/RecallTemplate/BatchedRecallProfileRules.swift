import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched recall profile must pass. Check returns its problems, or none.
    protocol BatchedRecallProfileRule {
        func check(_ item: BatchedRecallProfile) -> [String]
    }

    final class BatchedRecallProfileRequiredCategoryRule: BatchedRecallProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRecallProfile) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedRecallProfileAllowedDescriptionRule: BatchedRecallProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedRecallProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is blocked"]
            }
            return []
        }
    }

    final class BatchedRecallProfileCodeLengthRule: BatchedRecallProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedRecallProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedRecallProfileDurationMinutesRangeRule: BatchedRecallProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedRecallProfile) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedRecallProfileSequenceRangeRule: BatchedRecallProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedRecallProfile) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched recall profile.
    final class BatchedRecallProfileValidator {
        var rules: [any BatchedRecallProfileRule]

        init(rules: [any BatchedRecallProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedRecallProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedRecallProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedRecallProfile]) -> [String: [String]] {
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

    static func defaultBatchedRecallProfileValidator() -> BatchedRecallProfileValidator {
        return BatchedRecallProfileValidator(
            rules: [
                BatchedRecallProfileRequiredCategoryRule(message: "batched recall profile needs a value"),
                BatchedRecallProfileAllowedDescriptionRule(allowed: ["manual"]),
                BatchedRecallProfileCodeLengthRule(maxLength: 64),
                BatchedRecallProfileDurationMinutesRangeRule(min: 32, max: 120),
                BatchedRecallProfileSequenceRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
