import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a batched shift rule must pass. Check returns its problems, or none.
    protocol BatchedShiftRuleRule {
        func check(_ item: BatchedShiftRule) -> [String]
    }

    final class BatchedShiftRuleCodeLengthRule: BatchedShiftRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedShiftRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedShiftRuleCostRangeRule: BatchedShiftRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedShiftRule) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedShiftRuleSourceLengthRule: BatchedShiftRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedShiftRule) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched shift rule.
    final class BatchedShiftRuleValidator {
        var rules: [any BatchedShiftRuleRule]

        init(rules: [any BatchedShiftRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedShiftRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedShiftRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedShiftRule]) -> [String: [String]] {
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

    static func defaultBatchedShiftRuleValidator() -> BatchedShiftRuleValidator {
        return BatchedShiftRuleValidator(
            rules: [
                BatchedShiftRuleCodeLengthRule(maxLength: 1000),
                BatchedShiftRuleCostRangeRule(min: 7.3, max: 3542.5),
                BatchedShiftRuleSourceLengthRule(maxLength: 64),
            ]
        )
    }
}
