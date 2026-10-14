import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding checkpoint must pass. Check returns its problems, or none.
    protocol RoundingCheckpointRule {
        func check(_ item: RoundingCheckpoint) -> [String]
    }

    final class RoundingCheckpointRequiredDiagnosisCodeRule: RoundingCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingCheckpoint) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingCheckpointProcedureCodeLengthRule: RoundingCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingCheckpoint) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingCheckpointRequiredProcedureCodeRule: RoundingCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingCheckpoint) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingCheckpointRequiredCodeRule: RoundingCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingCheckpointAllowedLabelRule: RoundingCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RoundingCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    final class RoundingCheckpointRequiredLabelRule: RoundingCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rounding checkpoint.
    final class RoundingCheckpointValidator {
        var rules: [any RoundingCheckpointRule]

        init(rules: [any RoundingCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingCheckpoint]) -> [String: [String]] {
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

    static func defaultRoundingCheckpointValidator() -> RoundingCheckpointValidator {
        return RoundingCheckpointValidator(
            rules: [
                RoundingCheckpointRequiredDiagnosisCodeRule(message: "rounding checkpoint needs a value"),
                RoundingCheckpointProcedureCodeLengthRule(maxLength: 32),
                RoundingCheckpointRequiredProcedureCodeRule(message: "rounding checkpoint needs an entry"),
                RoundingCheckpointRequiredCodeRule(message: "rounding checkpoint needs a value"),
                RoundingCheckpointAllowedLabelRule(allowed: ["lenient"]),
                RoundingCheckpointRequiredLabelRule(message: "rounding checkpoint needs this field"),
            ]
        )
    }
}
