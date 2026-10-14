import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense rollup must pass. Check returns its problems, or none.
    protocol DispenseRollupRule {
        func check(_ item: DispenseRollup) -> [String]
    }

    final class DispenseRollupStartsAtRangeRule: DispenseRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseRollup) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseRollupCopayRangeRule: DispenseRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseRollup) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseRollupRequiredCodeRule: DispenseRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseRollupRequiredCategoryRule: DispenseRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseRollup) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseRollupRequiredRegionRule: DispenseRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseRollup) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a dispense rollup.
    final class DispenseRollupValidator {
        var rules: [any DispenseRollupRule]

        init(rules: [any DispenseRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseRollup) -> [String] {
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

        func requireValid(_ item: DispenseRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseRollup]) -> [String: [String]] {
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

    static func defaultDispenseRollupValidator() -> DispenseRollupValidator {
        return DispenseRollupValidator(
            rules: [
                DispenseRollupStartsAtRangeRule(min: 64, max: 64),
                DispenseRollupCopayRangeRule(min: 1.1, max: 846.3),
                DispenseRollupRequiredCodeRule(message: "dispense rollup needs a value"),
                DispenseRollupRequiredCategoryRule(message: "dispense rollup needs this field"),
                DispenseRollupRequiredRegionRule(message: "dispense rollup needs a value"),
            ]
        )
    }
}
