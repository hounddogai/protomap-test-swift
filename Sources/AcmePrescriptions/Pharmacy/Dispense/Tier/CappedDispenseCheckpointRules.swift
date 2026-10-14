import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped dispense checkpoint must pass. Check returns its problems, or none.
    protocol CappedDispenseCheckpointRule {
        func check(_ item: CappedDispenseCheckpoint) -> [String]
    }

    final class CappedDispenseCheckpointTitleLengthRule: CappedDispenseCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedDispenseCheckpoint) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedDispenseCheckpointCodePrefixRule: CappedDispenseCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedDispenseCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedDispenseCheckpointRequiredUnitRule: CappedDispenseCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDispenseCheckpoint) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedDispenseCheckpointRequiredPayerRule: CappedDispenseCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDispenseCheckpoint) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedDispenseCheckpointRequiredCodeRule: CappedDispenseCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDispenseCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedDispenseCheckpointRequiredTitleRule: CappedDispenseCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDispenseCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped dispense checkpoint.
    final class CappedDispenseCheckpointValidator {
        var rules: [any CappedDispenseCheckpointRule]

        init(rules: [any CappedDispenseCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedDispenseCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedDispenseCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedDispenseCheckpoint]) -> [String: [String]] {
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

    static func defaultCappedDispenseCheckpointValidator() -> CappedDispenseCheckpointValidator {
        return CappedDispenseCheckpointValidator(
            rules: [
                CappedDispenseCheckpointTitleLengthRule(maxLength: 3600),
                CappedDispenseCheckpointCodePrefixRule(prefix: "Q"),
                CappedDispenseCheckpointRequiredUnitRule(message: "capped dispense checkpoint needs a value"),
                CappedDispenseCheckpointRequiredPayerRule(message: "capped dispense checkpoint needs an entry"),
                CappedDispenseCheckpointRequiredCodeRule(message: "capped dispense checkpoint needs an entry"),
                CappedDispenseCheckpointRequiredTitleRule(message: "capped dispense checkpoint needs this field"),
            ]
        )
    }
}
