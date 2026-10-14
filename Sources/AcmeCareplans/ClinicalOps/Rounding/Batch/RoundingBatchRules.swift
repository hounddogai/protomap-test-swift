import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding batch must pass. Check returns its problems, or none.
    protocol RoundingBatchRule {
        func check(_ item: RoundingBatch) -> [String]
    }

    final class RoundingBatchRequiredDescriptionRule: RoundingBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingBatch) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingBatchRequiredLabelRule: RoundingBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingBatchCodeLengthRule: RoundingBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingBatchCapacityRangeRule: RoundingBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingBatch) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding batch.
    final class RoundingBatchValidator {
        var rules: [any RoundingBatchRule]

        init(rules: [any RoundingBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingBatch]) -> [String: [String]] {
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

    static func defaultRoundingBatchValidator() -> RoundingBatchValidator {
        return RoundingBatchValidator(
            rules: [
                RoundingBatchRequiredDescriptionRule(message: "rounding batch needs a value"),
                RoundingBatchRequiredLabelRule(message: "rounding batch needs this field"),
                RoundingBatchCodeLengthRule(maxLength: 32),
                RoundingBatchCapacityRangeRule(min: 16, max: 120),
            ]
        )
    }
}
