import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending discharge plan checkpoint must pass. Check returns its problems, or none.
    protocol PendingDischargePlanCheckpointRule {
        func check(_ item: PendingDischargePlanCheckpoint) -> [String]
    }

    final class PendingDischargePlanCheckpointVersionRangeRule: PendingDischargePlanCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingDischargePlanCheckpoint) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingDischargePlanCheckpointCodeLengthRule: PendingDischargePlanCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDischargePlanCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingDischargePlanCheckpointCodePrefixRule: PendingDischargePlanCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingDischargePlanCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingDischargePlanCheckpointRequiredLabelRule: PendingDischargePlanCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingDischargePlanCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingDischargePlanCheckpointLabelLengthRule: PendingDischargePlanCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDischargePlanCheckpoint) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingDischargePlanCheckpointUnitLengthRule: PendingDischargePlanCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDischargePlanCheckpoint) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending discharge plan checkpoint.
    final class PendingDischargePlanCheckpointValidator {
        var rules: [any PendingDischargePlanCheckpointRule]

        init(rules: [any PendingDischargePlanCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingDischargePlanCheckpoint) -> [String] {
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

        func requireValid(_ item: PendingDischargePlanCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingDischargePlanCheckpoint]) -> [String: [String]] {
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

    static func defaultPendingDischargePlanCheckpointValidator() -> PendingDischargePlanCheckpointValidator {
        return PendingDischargePlanCheckpointValidator(
            rules: [
                PendingDischargePlanCheckpointVersionRangeRule(min: 255, max: 1000),
                PendingDischargePlanCheckpointCodeLengthRule(maxLength: 16),
                PendingDischargePlanCheckpointCodePrefixRule(prefix: "Q"),
                PendingDischargePlanCheckpointRequiredLabelRule(
                    message: "pending discharge plan checkpoint needs a value"
                ),
                PendingDischargePlanCheckpointLabelLengthRule(maxLength: 80),
                PendingDischargePlanCheckpointUnitLengthRule(maxLength: 255),
            ]
        )
    }
}
