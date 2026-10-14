import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional slot override must pass. Check returns its problems, or none.
    protocol RegionalSlotOverrideRule {
        func check(_ item: RegionalSlotOverride) -> [String]
    }

    final class RegionalSlotOverrideRevisionRangeRule: RegionalSlotOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSlotOverride) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalSlotOverrideCodeLengthRule: RegionalSlotOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSlotOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalSlotOverrideRefillsRangeRule: RegionalSlotOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSlotOverride) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a regional slot override.
    final class RegionalSlotOverrideValidator {
        var rules: [any RegionalSlotOverrideRule]

        init(rules: [any RegionalSlotOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSlotOverride) -> [String] {
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

        func requireValid(_ item: RegionalSlotOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSlotOverride]) -> [String: [String]] {
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

    static func defaultRegionalSlotOverrideValidator() -> RegionalSlotOverrideValidator {
        return RegionalSlotOverrideValidator(
            rules: [
                RegionalSlotOverrideRevisionRangeRule(min: 32, max: 80),
                RegionalSlotOverrideCodeLengthRule(maxLength: 86400),
                RegionalSlotOverrideRefillsRangeRule(min: 32, max: 80),
            ]
        )
    }
}
