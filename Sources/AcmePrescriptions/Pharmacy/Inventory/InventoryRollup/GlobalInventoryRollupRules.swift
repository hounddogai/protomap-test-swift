import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global inventory rollup must pass. Check returns its problems, or none.
    protocol GlobalInventoryRollupRule {
        func check(_ item: GlobalInventoryRollup) -> [String]
    }

    final class GlobalInventoryRollupAllowedTitleRule: GlobalInventoryRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalInventoryRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is expired"]
            }
            return []
        }
    }

    final class GlobalInventoryRollupCapacityRangeRule: GlobalInventoryRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalInventoryRollup) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalInventoryRollupQuantityRangeRule: GlobalInventoryRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalInventoryRollup) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global inventory rollup.
    final class GlobalInventoryRollupValidator {
        var rules: [any GlobalInventoryRollupRule]

        init(rules: [any GlobalInventoryRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalInventoryRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalInventoryRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalInventoryRollup]) -> [String: [String]] {
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

    static func defaultGlobalInventoryRollupValidator() -> GlobalInventoryRollupValidator {
        return GlobalInventoryRollupValidator(
            rules: [
                GlobalInventoryRollupAllowedTitleRule(allowed: ["scheduled"]),
                GlobalInventoryRollupCapacityRangeRule(min: 64, max: 86400),
                GlobalInventoryRollupQuantityRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
