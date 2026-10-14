import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a strict slot checkpoint must pass. Check returns its problems, or none.
    protocol StrictSlotCheckpointRule {
        func check(_ item: StrictSlotCheckpoint) -> [String]
    }

    final class StrictSlotCheckpointCodePrefixRule: StrictSlotCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictSlotCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictSlotCheckpointCodeLengthRule: StrictSlotCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSlotCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictSlotCheckpointStartsAtRangeRule: StrictSlotCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSlotCheckpoint) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict slot checkpoint.
    final class StrictSlotCheckpointValidator {
        var rules: [any StrictSlotCheckpointRule]

        init(rules: [any StrictSlotCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSlotCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictSlotCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSlotCheckpoint]) -> [String: [String]] {
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

    static func defaultStrictSlotCheckpointValidator() -> StrictSlotCheckpointValidator {
        return StrictSlotCheckpointValidator(
            rules: [
                StrictSlotCheckpointCodePrefixRule(prefix: "OPS"),
                StrictSlotCheckpointCodeLengthRule(maxLength: 86400),
                StrictSlotCheckpointStartsAtRangeRule(min: 64, max: 3600),
            ]
        )
    }
}
