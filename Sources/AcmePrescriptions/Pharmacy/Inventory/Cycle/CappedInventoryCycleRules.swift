import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped inventory cycle must pass. Check returns its problems, or none.
    protocol CappedInventoryCycleRule {
        func check(_ item: CappedInventoryCycle) -> [String]
    }

    final class CappedInventoryCycleLimitRangeRule: CappedInventoryCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedInventoryCycle) -> [String] {
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

    final class CappedInventoryCycleExpiresAtRangeRule: CappedInventoryCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedInventoryCycle) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedInventoryCycleNameLengthRule: CappedInventoryCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedInventoryCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped inventory cycle.
    final class CappedInventoryCycleValidator {
        var rules: [any CappedInventoryCycleRule]

        init(rules: [any CappedInventoryCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedInventoryCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedInventoryCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedInventoryCycle]) -> [String: [String]] {
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

    static func defaultCappedInventoryCycleValidator() -> CappedInventoryCycleValidator {
        return CappedInventoryCycleValidator(
            rules: [
                CappedInventoryCycleLimitRangeRule(min: 64, max: 80),
                CappedInventoryCycleExpiresAtRangeRule(min: 80, max: 80),
                CappedInventoryCycleNameLengthRule(maxLength: 32),
            ]
        )
    }
}
