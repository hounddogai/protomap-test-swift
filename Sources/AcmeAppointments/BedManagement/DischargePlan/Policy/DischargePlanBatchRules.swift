import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan batch must pass. Check returns its problems, or none.
    protocol DischargePlanBatchRule {
        func check(_ item: DischargePlanBatch) -> [String]
    }

    final class DischargePlanBatchLabelLengthRule: DischargePlanBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanBatch) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanBatchRequiredLabelRule: DischargePlanBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanBatchCodeLengthRule: DischargePlanBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanBatchSequenceRangeRule: DischargePlanBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanBatch) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan batch.
    final class DischargePlanBatchValidator {
        var rules: [any DischargePlanBatchRule]

        init(rules: [any DischargePlanBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanBatch) -> [String] {
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

        func requireValid(_ item: DischargePlanBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanBatch]) -> [String: [String]] {
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

    static func defaultDischargePlanBatchValidator() -> DischargePlanBatchValidator {
        return DischargePlanBatchValidator(
            rules: [
                DischargePlanBatchLabelLengthRule(maxLength: 16),
                DischargePlanBatchRequiredLabelRule(message: "discharge plan batch needs this field"),
                DischargePlanBatchCodeLengthRule(maxLength: 1000),
                DischargePlanBatchSequenceRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
