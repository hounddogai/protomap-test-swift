import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot adjustment must pass. Check returns its problems, or none.
    protocol SlotAdjustmentRule {
        func check(_ item: SlotAdjustment) -> [String]
    }

    final class SlotAdjustmentProcedureCodeLengthRule: SlotAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotAdjustment) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotAdjustmentBatchSizeRangeRule: SlotAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotAdjustment) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotAdjustmentDosageMgRangeRule: SlotAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotAdjustment) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot adjustment.
    final class SlotAdjustmentValidator {
        var rules: [any SlotAdjustmentRule]

        init(rules: [any SlotAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotAdjustment]) -> [String: [String]] {
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

    static func defaultSlotAdjustmentValidator() -> SlotAdjustmentValidator {
        return SlotAdjustmentValidator(
            rules: [
                SlotAdjustmentProcedureCodeLengthRule(maxLength: 64),
                SlotAdjustmentBatchSizeRangeRule(min: 1000, max: 1000),
                SlotAdjustmentDosageMgRangeRule(min: 8.2, max: 2043.2),
            ]
        )
    }
}
