import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan override must pass. Check returns its problems, or none.
    protocol DischargePlanOverrideRule {
        func check(_ item: DischargePlanOverride) -> [String]
    }

    final class DischargePlanOverrideCodePrefixRule: DischargePlanOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DischargePlanOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DischargePlanOverrideCodeLengthRule: DischargePlanOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanOverrideSequenceRangeRule: DischargePlanOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanOverride) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanOverrideAttemptsRangeRule: DischargePlanOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanOverride) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a discharge plan override.
    final class DischargePlanOverrideValidator {
        var rules: [any DischargePlanOverrideRule]

        init(rules: [any DischargePlanOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanOverride) -> [String] {
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

        func requireValid(_ item: DischargePlanOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanOverride]) -> [String: [String]] {
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

    static func defaultDischargePlanOverrideValidator() -> DischargePlanOverrideValidator {
        return DischargePlanOverrideValidator(
            rules: [
                DischargePlanOverrideCodePrefixRule(prefix: "REF"),
                DischargePlanOverrideCodeLengthRule(maxLength: 120),
                DischargePlanOverrideSequenceRangeRule(min: 255, max: 1000),
                DischargePlanOverrideAttemptsRangeRule(min: 64, max: 255),
            ]
        )
    }
}
