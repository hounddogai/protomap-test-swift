import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score baseline must pass. Check returns its problems, or none.
    protocol RiskScoreBaselineRule {
        func check(_ item: RiskScoreBaseline) -> [String]
    }

    final class RiskScoreBaselineRequiredNameRule: RiskScoreBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreBaselineNameLengthRule: RiskScoreBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreBaselineTimezoneLengthRule: RiskScoreBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreBaseline) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreBaselineRequiredCodeRule: RiskScoreBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreBaselineRequiredTimezoneRule: RiskScoreBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreBaseline) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a risk score baseline.
    final class RiskScoreBaselineValidator {
        var rules: [any RiskScoreBaselineRule]

        init(rules: [any RiskScoreBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreBaseline]) -> [String: [String]] {
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

    static func defaultRiskScoreBaselineValidator() -> RiskScoreBaselineValidator {
        return RiskScoreBaselineValidator(
            rules: [
                RiskScoreBaselineRequiredNameRule(message: "risk score baseline needs this field"),
                RiskScoreBaselineNameLengthRule(maxLength: 86400),
                RiskScoreBaselineTimezoneLengthRule(maxLength: 120),
                RiskScoreBaselineRequiredCodeRule(message: "risk score baseline needs a value"),
                RiskScoreBaselineRequiredTimezoneRule(message: "risk score baseline needs this field"),
            ]
        )
    }
}
