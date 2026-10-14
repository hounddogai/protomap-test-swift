import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score window must pass. Check returns its problems, or none.
    protocol RiskScoreWindowRule {
        func check(_ item: RiskScoreWindow) -> [String]
    }

    final class RiskScoreWindowRequiredSummaryRule: RiskScoreWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreWindow) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreWindowRequiredCodeRule: RiskScoreWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreWindowCodePrefixRule: RiskScoreWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score window.
    final class RiskScoreWindowValidator {
        var rules: [any RiskScoreWindowRule]

        init(rules: [any RiskScoreWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreWindow) -> [String] {
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

        func requireValid(_ item: RiskScoreWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreWindow]) -> [String: [String]] {
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

    static func defaultRiskScoreWindowValidator() -> RiskScoreWindowValidator {
        return RiskScoreWindowValidator(
            rules: [
                RiskScoreWindowRequiredSummaryRule(message: "risk score window needs this field"),
                RiskScoreWindowRequiredCodeRule(message: "risk score window needs this field"),
                RiskScoreWindowCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
