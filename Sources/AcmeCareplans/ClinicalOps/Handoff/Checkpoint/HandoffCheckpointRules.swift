import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff checkpoint must pass. Check returns its problems, or none.
    protocol HandoffCheckpointRule {
        func check(_ item: HandoffCheckpoint) -> [String]
    }

    final class HandoffCheckpointRequiredTitleRule: HandoffCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffCheckpointCodeLengthRule: HandoffCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffCheckpointDiagnosisCodeLengthRule: HandoffCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffCheckpoint) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffCheckpointPatientRefLengthRule: HandoffCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffCheckpoint) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffCheckpointRequiredCodeRule: HandoffCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffCheckpointAllowedContactEmailRule: HandoffCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: HandoffCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff checkpoint.
    final class HandoffCheckpointValidator {
        var rules: [any HandoffCheckpointRule]

        init(rules: [any HandoffCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffCheckpoint) -> [String] {
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

        func requireValid(_ item: HandoffCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffCheckpoint]) -> [String: [String]] {
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

    static func defaultHandoffCheckpointValidator() -> HandoffCheckpointValidator {
        return HandoffCheckpointValidator(
            rules: [
                HandoffCheckpointRequiredTitleRule(message: "handoff checkpoint needs this field"),
                HandoffCheckpointCodeLengthRule(maxLength: 16),
                HandoffCheckpointDiagnosisCodeLengthRule(maxLength: 1000),
                HandoffCheckpointPatientRefLengthRule(maxLength: 120),
                HandoffCheckpointRequiredCodeRule(message: "handoff checkpoint needs this field"),
                HandoffCheckpointAllowedContactEmailRule(allowed: ["default", "default"]),
            ]
        )
    }
}
