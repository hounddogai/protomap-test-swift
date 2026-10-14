import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment checkpoint must pass. Check returns its problems, or none.
    protocol AssessmentCheckpointRule {
        func check(_ item: AssessmentCheckpoint) -> [String]
    }

    final class AssessmentCheckpointCodePrefixRule: AssessmentCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AssessmentCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AssessmentCheckpointRequiredCodeRule: AssessmentCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentCheckpointExternalRefLengthRule: AssessmentCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentCheckpoint) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentCheckpointRequiredExternalRefRule: AssessmentCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentCheckpoint) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentCheckpointCodeLengthRule: AssessmentCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment checkpoint.
    final class AssessmentCheckpointValidator {
        var rules: [any AssessmentCheckpointRule]

        init(rules: [any AssessmentCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentCheckpoint) -> [String] {
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

        func requireValid(_ item: AssessmentCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentCheckpoint]) -> [String: [String]] {
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

    static func defaultAssessmentCheckpointValidator() -> AssessmentCheckpointValidator {
        return AssessmentCheckpointValidator(
            rules: [
                AssessmentCheckpointCodePrefixRule(prefix: "OPS"),
                AssessmentCheckpointRequiredCodeRule(message: "assessment checkpoint needs this field"),
                AssessmentCheckpointExternalRefLengthRule(maxLength: 64),
                AssessmentCheckpointRequiredExternalRefRule(message: "assessment checkpoint needs this field"),
                AssessmentCheckpointCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
