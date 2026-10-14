import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary assessment checkpoint must pass. Check returns its problems, or none.
    protocol PrimaryAssessmentCheckpointRule {
        func check(_ item: PrimaryAssessmentCheckpoint) -> [String]
    }

    final class PrimaryAssessmentCheckpointRequiredCurrencyRule: PrimaryAssessmentCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAssessmentCheckpoint) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAssessmentCheckpointRevisionRangeRule: PrimaryAssessmentCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryAssessmentCheckpoint) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryAssessmentCheckpointAllowedCodeRule: PrimaryAssessmentCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryAssessmentCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class PrimaryAssessmentCheckpointCodeLengthRule: PrimaryAssessmentCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAssessmentCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAssessmentCheckpointAllergyLengthRule: PrimaryAssessmentCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAssessmentCheckpoint) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAssessmentCheckpointCurrencyLengthRule: PrimaryAssessmentCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAssessmentCheckpoint) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary assessment checkpoint.
    final class PrimaryAssessmentCheckpointValidator {
        var rules: [any PrimaryAssessmentCheckpointRule]

        init(rules: [any PrimaryAssessmentCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAssessmentCheckpoint) -> [String] {
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

        func requireValid(_ item: PrimaryAssessmentCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAssessmentCheckpoint]) -> [String: [String]] {
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

    static func defaultPrimaryAssessmentCheckpointValidator() -> PrimaryAssessmentCheckpointValidator {
        return PrimaryAssessmentCheckpointValidator(
            rules: [
                PrimaryAssessmentCheckpointRequiredCurrencyRule(
                    message: "primary assessment checkpoint needs this field"
                ),
                PrimaryAssessmentCheckpointRevisionRangeRule(min: 64, max: 64),
                PrimaryAssessmentCheckpointAllowedCodeRule(allowed: []),
                PrimaryAssessmentCheckpointCodeLengthRule(maxLength: 255),
                PrimaryAssessmentCheckpointAllergyLengthRule(maxLength: 16),
                PrimaryAssessmentCheckpointCurrencyLengthRule(maxLength: 86400),
            ]
        )
    }
}
