import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness checkpoint must pass. Check returns its problems, or none.
    protocol WitnessCheckpointRule {
        func check(_ item: WitnessCheckpoint) -> [String]
    }

    final class WitnessCheckpointRequiredTitleRule: WitnessCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessCheckpointCodePrefixRule: WitnessCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WitnessCheckpointVersionRangeRule: WitnessCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessCheckpoint) -> [String] {
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

    final class WitnessCheckpointProcedureCodeLengthRule: WitnessCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessCheckpoint) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessCheckpointCodeLengthRule: WitnessCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessCheckpointRequiredCodeRule: WitnessCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness checkpoint.
    final class WitnessCheckpointValidator {
        var rules: [any WitnessCheckpointRule]

        init(rules: [any WitnessCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessCheckpoint]) -> [String: [String]] {
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

    static func defaultWitnessCheckpointValidator() -> WitnessCheckpointValidator {
        return WitnessCheckpointValidator(
            rules: [
                WitnessCheckpointRequiredTitleRule(message: "witness checkpoint needs this field"),
                WitnessCheckpointCodePrefixRule(prefix: "Q"),
                WitnessCheckpointVersionRangeRule(min: 16, max: 80),
                WitnessCheckpointProcedureCodeLengthRule(maxLength: 32),
                WitnessCheckpointCodeLengthRule(maxLength: 86400),
                WitnessCheckpointRequiredCodeRule(message: "witness checkpoint needs an entry"),
            ]
        )
    }
}
