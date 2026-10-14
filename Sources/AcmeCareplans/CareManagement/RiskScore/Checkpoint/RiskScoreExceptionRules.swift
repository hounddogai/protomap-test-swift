import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score exception must pass. Check returns its problems, or none.
    protocol RiskScoreExceptionRule {
        func check(_ item: RiskScoreException) -> [String]
    }

    final class RiskScoreExceptionRequiredFacilityRule: RiskScoreExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreException) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreExceptionVersionRangeRule: RiskScoreExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreException) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RiskScoreExceptionEndsAtRangeRule: RiskScoreExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreException) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RiskScoreExceptionCodePrefixRule: RiskScoreExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreExceptionSourceLengthRule: RiskScoreExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreException) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score exception.
    final class RiskScoreExceptionValidator {
        var rules: [any RiskScoreExceptionRule]

        init(rules: [any RiskScoreExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreException]) -> [String: [String]] {
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

    static func defaultRiskScoreExceptionValidator() -> RiskScoreExceptionValidator {
        return RiskScoreExceptionValidator(
            rules: [
                RiskScoreExceptionRequiredFacilityRule(message: "risk score exception needs a value"),
                RiskScoreExceptionVersionRangeRule(min: 255, max: 86400),
                RiskScoreExceptionEndsAtRangeRule(min: 1000, max: 1000),
                RiskScoreExceptionCodePrefixRule(prefix: "Q"),
                RiskScoreExceptionSourceLengthRule(maxLength: 120),
            ]
        )
    }
}
