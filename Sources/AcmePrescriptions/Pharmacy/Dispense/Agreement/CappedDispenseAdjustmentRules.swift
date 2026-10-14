import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped dispense adjustment must pass. Check returns its problems, or none.
    protocol CappedDispenseAdjustmentRule {
        func check(_ item: CappedDispenseAdjustment) -> [String]
    }

    final class CappedDispenseAdjustmentCodePrefixRule: CappedDispenseAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedDispenseAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedDispenseAdjustmentUpdatedAtRangeRule: CappedDispenseAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedDispenseAdjustment) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedDispenseAdjustmentFloorValueRangeRule: CappedDispenseAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedDispenseAdjustment) -> [String] {
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

    final class CappedDispenseAdjustmentRequiredTitleRule: CappedDispenseAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDispenseAdjustment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped dispense adjustment.
    final class CappedDispenseAdjustmentValidator {
        var rules: [any CappedDispenseAdjustmentRule]

        init(rules: [any CappedDispenseAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedDispenseAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedDispenseAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedDispenseAdjustment]) -> [String: [String]] {
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

    static func defaultCappedDispenseAdjustmentValidator() -> CappedDispenseAdjustmentValidator {
        return CappedDispenseAdjustmentValidator(
            rules: [
                CappedDispenseAdjustmentCodePrefixRule(prefix: "REF"),
                CappedDispenseAdjustmentUpdatedAtRangeRule(min: 64, max: 120),
                CappedDispenseAdjustmentFloorValueRangeRule(min: 4.1, max: 4778.0),
                CappedDispenseAdjustmentRequiredTitleRule(message: "capped dispense adjustment needs a value"),
            ]
        )
    }
}
