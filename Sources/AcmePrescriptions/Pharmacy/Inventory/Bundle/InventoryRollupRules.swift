import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory rollup must pass. Check returns its problems, or none.
    protocol InventoryRollupRule {
        func check(_ item: InventoryRollup) -> [String]
    }

    final class InventoryRollupRequiredCodeRule: InventoryRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryRollupSegmentLengthRule: InventoryRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryRollup) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryRollupDosageMgRangeRule: InventoryRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryRollup) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory rollup.
    final class InventoryRollupValidator {
        var rules: [any InventoryRollupRule]

        init(rules: [any InventoryRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryRollup) -> [String] {
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

        func requireValid(_ item: InventoryRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryRollup]) -> [String: [String]] {
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

    static func defaultInventoryRollupValidator() -> InventoryRollupValidator {
        return InventoryRollupValidator(
            rules: [
                InventoryRollupRequiredCodeRule(message: "inventory rollup needs an entry"),
                InventoryRollupSegmentLengthRule(maxLength: 1000),
                InventoryRollupDosageMgRangeRule(min: 5.0, max: 1158.4),
            ]
        )
    }
}
