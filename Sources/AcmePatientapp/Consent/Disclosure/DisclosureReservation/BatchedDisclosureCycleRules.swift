import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched disclosure cycle must pass. Check returns its problems, or none.
    protocol BatchedDisclosureCycleRule {
        func check(_ item: BatchedDisclosureCycle) -> [String]
    }

    final class BatchedDisclosureCycleCodeLengthRule: BatchedDisclosureCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDisclosureCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDisclosureCycleRequiredCodeRule: BatchedDisclosureCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDisclosureCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDisclosureCycleBatchSizeRangeRule: BatchedDisclosureCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDisclosureCycle) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedDisclosureCycleRequiredNameRule: BatchedDisclosureCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDisclosureCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDisclosureCycleNameLengthRule: BatchedDisclosureCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDisclosureCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDisclosureCycleCostRangeRule: BatchedDisclosureCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDisclosureCycle) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched disclosure cycle.
    final class BatchedDisclosureCycleValidator {
        var rules: [any BatchedDisclosureCycleRule]

        init(rules: [any BatchedDisclosureCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDisclosureCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedDisclosureCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDisclosureCycle]) -> [String: [String]] {
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

    static func defaultBatchedDisclosureCycleValidator() -> BatchedDisclosureCycleValidator {
        return BatchedDisclosureCycleValidator(
            rules: [
                BatchedDisclosureCycleCodeLengthRule(maxLength: 1000),
                BatchedDisclosureCycleRequiredCodeRule(message: "batched disclosure cycle needs this field"),
                BatchedDisclosureCycleBatchSizeRangeRule(min: 64, max: 86400),
                BatchedDisclosureCycleRequiredNameRule(message: "batched disclosure cycle needs this field"),
                BatchedDisclosureCycleNameLengthRule(maxLength: 32),
                BatchedDisclosureCycleCostRangeRule(min: 7.2, max: 2597.1),
            ]
        )
    }
}
