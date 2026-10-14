import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped goal agreement must pass. Check returns its problems, or none.
    protocol CappedGoalAgreementRule {
        func check(_ item: CappedGoalAgreement) -> [String]
    }

    final class CappedGoalAgreementDurationMinutesRangeRule: CappedGoalAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedGoalAgreement) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedGoalAgreementCodePrefixRule: CappedGoalAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedGoalAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedGoalAgreementScoreRangeRule: CappedGoalAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedGoalAgreement) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedGoalAgreementRequiredCodeRule: CappedGoalAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedGoalAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedGoalAgreementAllowedCodeRule: CappedGoalAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedGoalAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a capped goal agreement.
    final class CappedGoalAgreementValidator {
        var rules: [any CappedGoalAgreementRule]

        init(rules: [any CappedGoalAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedGoalAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedGoalAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedGoalAgreement]) -> [String: [String]] {
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

    static func defaultCappedGoalAgreementValidator() -> CappedGoalAgreementValidator {
        return CappedGoalAgreementValidator(
            rules: [
                CappedGoalAgreementDurationMinutesRangeRule(min: 16, max: 120),
                CappedGoalAgreementCodePrefixRule(prefix: "Q"),
                CappedGoalAgreementScoreRangeRule(min: 5.7, max: 2945.9),
                CappedGoalAgreementRequiredCodeRule(message: "capped goal agreement needs an entry"),
                CappedGoalAgreementAllowedCodeRule(allowed: ["legacy", "manual"]),
            ]
        )
    }
}
