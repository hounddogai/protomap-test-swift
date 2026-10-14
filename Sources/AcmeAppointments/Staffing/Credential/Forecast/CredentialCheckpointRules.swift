import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential checkpoint must pass. Check returns its problems, or none.
    protocol CredentialCheckpointRule {
        func check(_ item: CredentialCheckpoint) -> [String]
    }

    final class CredentialCheckpointNameLengthRule: CredentialCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialCheckpoint) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialCheckpointRequiredNameRule: CredentialCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialCheckpointDiagnosisCodeLengthRule: CredentialCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialCheckpoint) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialCheckpointRequiredDiagnosisCodeRule: CredentialCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialCheckpoint) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a credential checkpoint.
    final class CredentialCheckpointValidator {
        var rules: [any CredentialCheckpointRule]

        init(rules: [any CredentialCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialCheckpoint) -> [String] {
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

        func requireValid(_ item: CredentialCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialCheckpoint]) -> [String: [String]] {
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

    static func defaultCredentialCheckpointValidator() -> CredentialCheckpointValidator {
        return CredentialCheckpointValidator(
            rules: [
                CredentialCheckpointNameLengthRule(maxLength: 120),
                CredentialCheckpointRequiredNameRule(message: "credential checkpoint needs this field"),
                CredentialCheckpointDiagnosisCodeLengthRule(maxLength: 120),
                CredentialCheckpointRequiredDiagnosisCodeRule(message: "credential checkpoint needs an entry"),
            ]
        )
    }
}
