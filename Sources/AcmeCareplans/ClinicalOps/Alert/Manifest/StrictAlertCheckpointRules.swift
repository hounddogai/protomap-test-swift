import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict alert checkpoint must pass. Check returns its problems, or none.
    protocol StrictAlertCheckpointRule {
        func check(_ item: StrictAlertCheckpoint) -> [String]
    }

    final class StrictAlertCheckpointRequiredWardRule: StrictAlertCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAlertCheckpoint) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictAlertCheckpointCodePrefixRule: StrictAlertCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictAlertCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictAlertCheckpointProcedureCodeLengthRule: StrictAlertCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAlertCheckpoint) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict alert checkpoint.
    final class StrictAlertCheckpointValidator {
        var rules: [any StrictAlertCheckpointRule]

        init(rules: [any StrictAlertCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictAlertCheckpoint) -> [String] {
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

        func requireValid(_ item: StrictAlertCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictAlertCheckpoint]) -> [String: [String]] {
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

    static func defaultStrictAlertCheckpointValidator() -> StrictAlertCheckpointValidator {
        return StrictAlertCheckpointValidator(
            rules: [
                StrictAlertCheckpointRequiredWardRule(message: "strict alert checkpoint needs this field"),
                StrictAlertCheckpointCodePrefixRule(prefix: "Q"),
                StrictAlertCheckpointProcedureCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
