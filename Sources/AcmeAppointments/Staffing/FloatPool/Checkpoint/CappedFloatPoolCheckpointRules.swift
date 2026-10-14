import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped float pool checkpoint must pass. Check returns its problems, or none.
    protocol CappedFloatPoolCheckpointRule {
        func check(_ item: CappedFloatPoolCheckpoint) -> [String]
    }

    final class CappedFloatPoolCheckpointLabelLengthRule: CappedFloatPoolCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedFloatPoolCheckpoint) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedFloatPoolCheckpointAllowedCodeRule: CappedFloatPoolCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedFloatPoolCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class CappedFloatPoolCheckpointCodePrefixRule: CappedFloatPoolCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedFloatPoolCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedFloatPoolCheckpointMinimumRangeRule: CappedFloatPoolCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedFloatPoolCheckpoint) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedFloatPoolCheckpointRequiredCodeRule: CappedFloatPoolCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedFloatPoolCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedFloatPoolCheckpointVisitMinutesRangeRule: CappedFloatPoolCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedFloatPoolCheckpoint) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped float pool checkpoint.
    final class CappedFloatPoolCheckpointValidator {
        var rules: [any CappedFloatPoolCheckpointRule]

        init(rules: [any CappedFloatPoolCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedFloatPoolCheckpoint) -> [String] {
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

        func requireValid(_ item: CappedFloatPoolCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedFloatPoolCheckpoint]) -> [String: [String]] {
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

    static func defaultCappedFloatPoolCheckpointValidator() -> CappedFloatPoolCheckpointValidator {
        return CappedFloatPoolCheckpointValidator(
            rules: [
                CappedFloatPoolCheckpointLabelLengthRule(maxLength: 32),
                CappedFloatPoolCheckpointAllowedCodeRule(allowed: ["pending", "legacy", "capped"]),
                CappedFloatPoolCheckpointCodePrefixRule(prefix: "X"),
                CappedFloatPoolCheckpointMinimumRangeRule(min: 6.6, max: 1218.6),
                CappedFloatPoolCheckpointRequiredCodeRule(message: "capped float pool checkpoint needs a value"),
                CappedFloatPoolCheckpointVisitMinutesRangeRule(min: 1000, max: 86400),
            ]
        )
    }
}
