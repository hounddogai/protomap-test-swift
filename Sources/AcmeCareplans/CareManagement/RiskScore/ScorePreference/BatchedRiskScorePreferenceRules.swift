import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched risk score preference must pass. Check returns its problems, or none.
    protocol BatchedRiskScorePreferenceRule {
        func check(_ item: BatchedRiskScorePreference) -> [String]
    }

    final class BatchedRiskScorePreferenceRequiredCodeRule: BatchedRiskScorePreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRiskScorePreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedRiskScorePreferenceAllowedPatientRefRule: BatchedRiskScorePreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedRiskScorePreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is duplicated"]
            }
            return []
        }
    }

    final class BatchedRiskScorePreferenceAmountRangeRule: BatchedRiskScorePreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedRiskScorePreference) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedRiskScorePreferenceNameLengthRule: BatchedRiskScorePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedRiskScorePreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedRiskScorePreferencePayerLengthRule: BatchedRiskScorePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedRiskScorePreference) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched risk score preference.
    final class BatchedRiskScorePreferenceValidator {
        var rules: [any BatchedRiskScorePreferenceRule]

        init(rules: [any BatchedRiskScorePreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedRiskScorePreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedRiskScorePreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedRiskScorePreference]) -> [String: [String]] {
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

    static func defaultBatchedRiskScorePreferenceValidator() -> BatchedRiskScorePreferenceValidator {
        return BatchedRiskScorePreferenceValidator(
            rules: [
                BatchedRiskScorePreferenceRequiredCodeRule(message: "batched risk score preference needs a value"),
                BatchedRiskScorePreferenceAllowedPatientRefRule(allowed: ["capped", "primary"]),
                BatchedRiskScorePreferenceAmountRangeRule(min: 5.2, max: 1117.5),
                BatchedRiskScorePreferenceNameLengthRule(maxLength: 16),
                BatchedRiskScorePreferencePayerLengthRule(maxLength: 86400),
            ]
        )
    }
}
