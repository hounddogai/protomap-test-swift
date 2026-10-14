import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary outreach checkpoint must pass. Check returns its problems, or none.
    protocol PrimaryOutreachCheckpointRule {
        func check(_ item: PrimaryOutreachCheckpoint) -> [String]
    }

    final class PrimaryOutreachCheckpointClinicianIDLengthRule: PrimaryOutreachCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOutreachCheckpoint) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOutreachCheckpointRequiredLabelRule: PrimaryOutreachCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOutreachCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOutreachCheckpointRequiredCodeRule: PrimaryOutreachCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOutreachCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOutreachCheckpointCodeLengthRule: PrimaryOutreachCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOutreachCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOutreachCheckpointRequiredClinicianIDRule: PrimaryOutreachCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOutreachCheckpoint) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOutreachCheckpointActiveGuardRule: PrimaryOutreachCheckpointRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PrimaryOutreachCheckpoint) -> [String] {
            if item.active && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a primary outreach checkpoint.
    final class PrimaryOutreachCheckpointValidator {
        var rules: [any PrimaryOutreachCheckpointRule]

        init(rules: [any PrimaryOutreachCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOutreachCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryOutreachCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOutreachCheckpoint]) -> [String: [String]] {
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

    static func defaultPrimaryOutreachCheckpointValidator() -> PrimaryOutreachCheckpointValidator {
        return PrimaryOutreachCheckpointValidator(
            rules: [
                PrimaryOutreachCheckpointClinicianIDLengthRule(maxLength: 32),
                PrimaryOutreachCheckpointRequiredLabelRule(message: "primary outreach checkpoint needs a value"),
                PrimaryOutreachCheckpointRequiredCodeRule(message: "primary outreach checkpoint needs a value"),
                PrimaryOutreachCheckpointCodeLengthRule(maxLength: 80),
                PrimaryOutreachCheckpointRequiredClinicianIDRule(message: "primary outreach checkpoint needs a value"),
                PrimaryOutreachCheckpointActiveGuardRule(limit: 3.9),
            ]
        )
    }
}
