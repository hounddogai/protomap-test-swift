import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling rounding slot must pass. Check returns its problems, or none.
    protocol RollingRoundingSlotRule {
        func check(_ item: RollingRoundingSlot) -> [String]
    }

    final class RollingRoundingSlotExpiresAtRangeRule: RollingRoundingSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingRoundingSlot) -> [String] {
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

    final class RollingRoundingSlotRateRangeRule: RollingRoundingSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingRoundingSlot) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingRoundingSlotCodeLengthRule: RollingRoundingSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRoundingSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling rounding slot.
    final class RollingRoundingSlotValidator {
        var rules: [any RollingRoundingSlotRule]

        init(rules: [any RollingRoundingSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRoundingSlot) -> [String] {
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

        func requireValid(_ item: RollingRoundingSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRoundingSlot]) -> [String: [String]] {
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

    static func defaultRollingRoundingSlotValidator() -> RollingRoundingSlotValidator {
        return RollingRoundingSlotValidator(
            rules: [
                RollingRoundingSlotExpiresAtRangeRule(min: 64, max: 80),
                RollingRoundingSlotRateRangeRule(min: 8.2, max: 1267.4),
                RollingRoundingSlotCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
