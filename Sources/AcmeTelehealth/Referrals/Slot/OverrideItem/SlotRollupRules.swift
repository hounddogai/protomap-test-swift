import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot rollup must pass. Check returns its problems, or none.
    protocol SlotRollupRule {
        func check(_ item: SlotRollup) -> [String]
    }

    final class SlotRollupCategoryLengthRule: SlotRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotRollup) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotRollupRetriesRangeRule: SlotRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotRollup) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SlotRollupSegmentLengthRule: SlotRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotRollup) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotRollupCostRangeRule: SlotRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotRollup) -> [String] {
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

    /// Runs every rule of a slot rollup.
    final class SlotRollupValidator {
        var rules: [any SlotRollupRule]

        init(rules: [any SlotRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotRollup) -> [String] {
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

        func requireValid(_ item: SlotRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotRollup]) -> [String: [String]] {
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

    static func defaultSlotRollupValidator() -> SlotRollupValidator {
        return SlotRollupValidator(
            rules: [
                SlotRollupCategoryLengthRule(maxLength: 80),
                SlotRollupRetriesRangeRule(min: 64, max: 120),
                SlotRollupSegmentLengthRule(maxLength: 1000),
                SlotRollupCostRangeRule(min: 3.2, max: 3797.8),
            ]
        )
    }
}
