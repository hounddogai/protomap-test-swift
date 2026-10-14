import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive priority rollup must pass. Check returns its problems, or none.
    protocol AdaptivePriorityRollupRule {
        func check(_ item: AdaptivePriorityRollup) -> [String]
    }

    final class AdaptivePriorityRollupCodePrefixRule: AdaptivePriorityRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptivePriorityRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptivePriorityRollupCodeLengthRule: AdaptivePriorityRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptivePriorityRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptivePriorityRollupCapacityRangeRule: AdaptivePriorityRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptivePriorityRollup) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptivePriorityRollupLabelLengthRule: AdaptivePriorityRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptivePriorityRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptivePriorityRollupEncounterIDLengthRule: AdaptivePriorityRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptivePriorityRollup) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptivePriorityRollupDurationMinutesRangeRule: AdaptivePriorityRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptivePriorityRollup) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive priority rollup.
    final class AdaptivePriorityRollupValidator {
        var rules: [any AdaptivePriorityRollupRule]

        init(rules: [any AdaptivePriorityRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptivePriorityRollup) -> [String] {
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

        func requireValid(_ item: AdaptivePriorityRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptivePriorityRollup]) -> [String: [String]] {
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

    static func defaultAdaptivePriorityRollupValidator() -> AdaptivePriorityRollupValidator {
        return AdaptivePriorityRollupValidator(
            rules: [
                AdaptivePriorityRollupCodePrefixRule(prefix: "Q"),
                AdaptivePriorityRollupCodeLengthRule(maxLength: 16),
                AdaptivePriorityRollupCapacityRangeRule(min: 1000, max: 3600),
                AdaptivePriorityRollupLabelLengthRule(maxLength: 80),
                AdaptivePriorityRollupEncounterIDLengthRule(maxLength: 120),
                AdaptivePriorityRollupDurationMinutesRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
