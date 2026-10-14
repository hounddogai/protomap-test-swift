import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling slot rollup must pass. Check returns its problems, or none.
    protocol RollingSlotRollupRule {
        func check(_ item: RollingSlotRollup) -> [String]
    }

    final class RollingSlotRollupSpecialtyLengthRule: RollingSlotRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSlotRollup) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingSlotRollupPriorityRangeRule: RollingSlotRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingSlotRollup) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingSlotRollupCopayRangeRule: RollingSlotRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingSlotRollup) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingSlotRollupRatioRangeRule: RollingSlotRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingSlotRollup) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingSlotRollupCodeLengthRule: RollingSlotRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSlotRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling slot rollup.
    final class RollingSlotRollupValidator {
        var rules: [any RollingSlotRollupRule]

        init(rules: [any RollingSlotRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingSlotRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingSlotRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingSlotRollup]) -> [String: [String]] {
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

    static func defaultRollingSlotRollupValidator() -> RollingSlotRollupValidator {
        return RollingSlotRollupValidator(
            rules: [
                RollingSlotRollupSpecialtyLengthRule(maxLength: 255),
                RollingSlotRollupPriorityRangeRule(min: 120, max: 3600),
                RollingSlotRollupCopayRangeRule(min: 6.0, max: 3625.2),
                RollingSlotRollupRatioRangeRule(min: 8.3, max: 4152.4),
                RollingSlotRollupCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
