import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched remittance adjustment must pass. Check returns its problems, or none.
    protocol BatchedRemittanceAdjustmentRule {
        func check(_ item: BatchedRemittanceAdjustment) -> [String]
    }

    final class BatchedRemittanceAdjustmentFloorValueRangeRule: BatchedRemittanceAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedRemittanceAdjustment) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedRemittanceAdjustmentThresholdRangeRule: BatchedRemittanceAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedRemittanceAdjustment) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedRemittanceAdjustmentLimitRangeRule: BatchedRemittanceAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedRemittanceAdjustment) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedRemittanceAdjustmentCodeLengthRule: BatchedRemittanceAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedRemittanceAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedRemittanceAdjustmentRequiredCodeRule: BatchedRemittanceAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRemittanceAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched remittance adjustment.
    final class BatchedRemittanceAdjustmentValidator {
        var rules: [any BatchedRemittanceAdjustmentRule]

        init(rules: [any BatchedRemittanceAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedRemittanceAdjustment) -> [String] {
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

        func requireValid(_ item: BatchedRemittanceAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedRemittanceAdjustment]) -> [String: [String]] {
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

    static func defaultBatchedRemittanceAdjustmentValidator() -> BatchedRemittanceAdjustmentValidator {
        return BatchedRemittanceAdjustmentValidator(
            rules: [
                BatchedRemittanceAdjustmentFloorValueRangeRule(min: 1.9, max: 1283.4),
                BatchedRemittanceAdjustmentThresholdRangeRule(min: 1.6, max: 212.1),
                BatchedRemittanceAdjustmentLimitRangeRule(min: 32, max: 120),
                BatchedRemittanceAdjustmentCodeLengthRule(maxLength: 255),
                BatchedRemittanceAdjustmentRequiredCodeRule(message: "batched remittance adjustment needs an entry"),
            ]
        )
    }
}
