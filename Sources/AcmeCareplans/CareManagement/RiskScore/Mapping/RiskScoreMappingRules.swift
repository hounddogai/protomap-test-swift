import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score mapping must pass. Check returns its problems, or none.
    protocol RiskScoreMappingRule {
        func check(_ item: RiskScoreMapping) -> [String]
    }

    final class RiskScoreMappingAllowedNameRule: RiskScoreMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class RiskScoreMappingRequiredDescriptionRule: RiskScoreMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreMapping) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreMappingNameLengthRule: RiskScoreMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreMappingRateRangeRule: RiskScoreMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreMapping) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RiskScoreMappingCodePrefixRule: RiskScoreMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score mapping.
    final class RiskScoreMappingValidator {
        var rules: [any RiskScoreMappingRule]

        init(rules: [any RiskScoreMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreMapping]) -> [String: [String]] {
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

    static func defaultRiskScoreMappingValidator() -> RiskScoreMappingValidator {
        return RiskScoreMappingValidator(
            rules: [
                RiskScoreMappingAllowedNameRule(allowed: ["seasonal", "batched"]),
                RiskScoreMappingRequiredDescriptionRule(message: "risk score mapping needs a value"),
                RiskScoreMappingNameLengthRule(maxLength: 80),
                RiskScoreMappingRateRangeRule(min: 8.1, max: 335.7),
                RiskScoreMappingCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
