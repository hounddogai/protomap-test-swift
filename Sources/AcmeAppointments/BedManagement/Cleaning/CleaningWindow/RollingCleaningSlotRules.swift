import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling cleaning slot must pass. Check returns its problems, or none.
    protocol RollingCleaningSlotRule {
        func check(_ item: RollingCleaningSlot) -> [String]
    }

    final class RollingCleaningSlotTitleLengthRule: RollingCleaningSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCleaningSlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCleaningSlotCeilingRangeRule: RollingCleaningSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCleaningSlot) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingCleaningSlotCodeLengthRule: RollingCleaningSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCleaningSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling cleaning slot.
    final class RollingCleaningSlotValidator {
        var rules: [any RollingCleaningSlotRule]

        init(rules: [any RollingCleaningSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCleaningSlot) -> [String] {
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

        func requireValid(_ item: RollingCleaningSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCleaningSlot]) -> [String: [String]] {
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

    static func defaultRollingCleaningSlotValidator() -> RollingCleaningSlotValidator {
        return RollingCleaningSlotValidator(
            rules: [
                RollingCleaningSlotTitleLengthRule(maxLength: 120),
                RollingCleaningSlotCeilingRangeRule(min: 4.4, max: 410.8),
                RollingCleaningSlotCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
