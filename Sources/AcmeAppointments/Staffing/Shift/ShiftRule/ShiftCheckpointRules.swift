import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift checkpoint must pass. Check returns its problems, or none.
    protocol ShiftCheckpointRule {
        func check(_ item: ShiftCheckpoint) -> [String]
    }

    final class ShiftCheckpointAllowedCurrencyRule: ShiftCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ShiftCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is not allowed"]
            }
            return []
        }
    }

    final class ShiftCheckpointCodeLengthRule: ShiftCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftCheckpointThresholdRangeRule: ShiftCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftCheckpoint) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ShiftCheckpointCodePrefixRule: ShiftCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ShiftCheckpointDescriptionLengthRule: ShiftCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftCheckpoint) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift checkpoint.
    final class ShiftCheckpointValidator {
        var rules: [any ShiftCheckpointRule]

        init(rules: [any ShiftCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftCheckpoint) -> [String] {
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

        func requireValid(_ item: ShiftCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftCheckpoint]) -> [String: [String]] {
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

    static func defaultShiftCheckpointValidator() -> ShiftCheckpointValidator {
        return ShiftCheckpointValidator(
            rules: [
                ShiftCheckpointAllowedCurrencyRule(allowed: ["legacy", "legacy"]),
                ShiftCheckpointCodeLengthRule(maxLength: 64),
                ShiftCheckpointThresholdRangeRule(min: 2.1, max: 1538.7),
                ShiftCheckpointCodePrefixRule(prefix: "ACM"),
                ShiftCheckpointDescriptionLengthRule(maxLength: 32),
            ]
        )
    }
}
