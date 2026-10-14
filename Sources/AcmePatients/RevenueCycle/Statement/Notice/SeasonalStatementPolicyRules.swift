import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a seasonal statement policy must pass. Check returns its problems, or none.
    protocol SeasonalStatementPolicyRule {
        func check(_ item: SeasonalStatementPolicy) -> [String]
    }

    final class SeasonalStatementPolicyCodePrefixRule: SeasonalStatementPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalStatementPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalStatementPolicyRequiredCodeRule: SeasonalStatementPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalStatementPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalStatementPolicyBatchSizeRangeRule: SeasonalStatementPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalStatementPolicy) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalStatementPolicyNameLengthRule: SeasonalStatementPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalStatementPolicy) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalStatementPolicyAllowedPatientRefRule: SeasonalStatementPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalStatementPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal statement policy.
    final class SeasonalStatementPolicyValidator {
        var rules: [any SeasonalStatementPolicyRule]

        init(rules: [any SeasonalStatementPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalStatementPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalStatementPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalStatementPolicy]) -> [String: [String]] {
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

    static func defaultSeasonalStatementPolicyValidator() -> SeasonalStatementPolicyValidator {
        return SeasonalStatementPolicyValidator(
            rules: [
                SeasonalStatementPolicyCodePrefixRule(prefix: "Q"),
                SeasonalStatementPolicyRequiredCodeRule(message: "seasonal statement policy needs a value"),
                SeasonalStatementPolicyBatchSizeRangeRule(min: 255, max: 1000),
                SeasonalStatementPolicyNameLengthRule(maxLength: 80),
                SeasonalStatementPolicyAllowedPatientRefRule(allowed: ["scheduled", "fallback", "lenient"]),
            ]
        )
    }
}
