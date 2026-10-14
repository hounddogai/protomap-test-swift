import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense cycle must pass. Check returns its problems, or none.
    protocol DispenseCycleRule {
        func check(_ item: DispenseCycle) -> [String]
    }

    final class DispenseCycleCopayRangeRule: DispenseCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseCycle) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseCycleCapacityRangeRule: DispenseCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseCycle) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseCycleCodeLengthRule: DispenseCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseCycleAllowedCodeRule: DispenseCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense cycle.
    final class DispenseCycleValidator {
        var rules: [any DispenseCycleRule]

        init(rules: [any DispenseCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseCycle]) -> [String: [String]] {
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

    static func defaultDispenseCycleValidator() -> DispenseCycleValidator {
        return DispenseCycleValidator(
            rules: [
                DispenseCycleCopayRangeRule(min: 5.8, max: 1307.8),
                DispenseCycleCapacityRangeRule(min: 32, max: 120),
                DispenseCycleCodeLengthRule(maxLength: 120),
                DispenseCycleAllowedCodeRule(allowed: []),
            ]
        )
    }
}
