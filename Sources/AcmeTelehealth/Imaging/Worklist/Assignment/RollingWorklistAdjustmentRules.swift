import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling worklist adjustment must pass. Check returns its problems, or none.
    protocol RollingWorklistAdjustmentRule {
        func check(_ item: RollingWorklistAdjustment) -> [String]
    }

    final class RollingWorklistAdjustmentCodeLengthRule: RollingWorklistAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingWorklistAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingWorklistAdjustmentCopayRangeRule: RollingWorklistAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingWorklistAdjustment) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingWorklistAdjustmentCodePrefixRule: RollingWorklistAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingWorklistAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingWorklistAdjustmentRequiredCodeRule: RollingWorklistAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingWorklistAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingWorklistAdjustmentQuantityRangeRule: RollingWorklistAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingWorklistAdjustment) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling worklist adjustment.
    final class RollingWorklistAdjustmentValidator {
        var rules: [any RollingWorklistAdjustmentRule]

        init(rules: [any RollingWorklistAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingWorklistAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingWorklistAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingWorklistAdjustment]) -> [String: [String]] {
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

    static func defaultRollingWorklistAdjustmentValidator() -> RollingWorklistAdjustmentValidator {
        return RollingWorklistAdjustmentValidator(
            rules: [
                RollingWorklistAdjustmentCodeLengthRule(maxLength: 255),
                RollingWorklistAdjustmentCopayRangeRule(min: 8.0, max: 4794.8),
                RollingWorklistAdjustmentCodePrefixRule(prefix: "Q"),
                RollingWorklistAdjustmentRequiredCodeRule(message: "rolling worklist adjustment needs this field"),
                RollingWorklistAdjustmentQuantityRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
