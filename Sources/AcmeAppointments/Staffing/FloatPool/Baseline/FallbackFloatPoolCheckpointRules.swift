import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback float pool checkpoint must pass. Check returns its problems, or none.
    protocol FallbackFloatPoolCheckpointRule {
        func check(_ item: FallbackFloatPoolCheckpoint) -> [String]
    }

    final class FallbackFloatPoolCheckpointAttemptsRangeRule: FallbackFloatPoolCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackFloatPoolCheckpoint) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackFloatPoolCheckpointLabelLengthRule: FallbackFloatPoolCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackFloatPoolCheckpoint) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackFloatPoolCheckpointAllowedCodeRule: FallbackFloatPoolCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackFloatPoolCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class FallbackFloatPoolCheckpointCodePrefixRule: FallbackFloatPoolCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackFloatPoolCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackFloatPoolCheckpointMinimumRangeRule: FallbackFloatPoolCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackFloatPoolCheckpoint) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a fallback float pool checkpoint.
    final class FallbackFloatPoolCheckpointValidator {
        var rules: [any FallbackFloatPoolCheckpointRule]

        init(rules: [any FallbackFloatPoolCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackFloatPoolCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackFloatPoolCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackFloatPoolCheckpoint]) -> [String: [String]] {
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

    static func defaultFallbackFloatPoolCheckpointValidator() -> FallbackFloatPoolCheckpointValidator {
        return FallbackFloatPoolCheckpointValidator(
            rules: [
                FallbackFloatPoolCheckpointAttemptsRangeRule(min: 32, max: 3600),
                FallbackFloatPoolCheckpointLabelLengthRule(maxLength: 86400),
                FallbackFloatPoolCheckpointAllowedCodeRule(allowed: ["strict", "global", "primary"]),
                FallbackFloatPoolCheckpointCodePrefixRule(prefix: "X"),
                FallbackFloatPoolCheckpointMinimumRangeRule(min: 3.6, max: 4115.4),
            ]
        )
    }
}
