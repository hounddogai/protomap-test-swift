import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default risk score window must pass. Check returns its problems, or none.
    protocol DefaultRiskScoreWindowRule {
        func check(_ item: DefaultRiskScoreWindow) -> [String]
    }

    final class DefaultRiskScoreWindowAllowedCodeRule: DefaultRiskScoreWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultRiskScoreWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class DefaultRiskScoreWindowCodeLengthRule: DefaultRiskScoreWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRiskScoreWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRiskScoreWindowRequiredTitleRule: DefaultRiskScoreWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRiskScoreWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRiskScoreWindowRequiredCodeRule: DefaultRiskScoreWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRiskScoreWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRiskScoreWindowCostRangeRule: DefaultRiskScoreWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRiskScoreWindow) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a default risk score window.
    final class DefaultRiskScoreWindowValidator {
        var rules: [any DefaultRiskScoreWindowRule]

        init(rules: [any DefaultRiskScoreWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRiskScoreWindow) -> [String] {
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

        func requireValid(_ item: DefaultRiskScoreWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRiskScoreWindow]) -> [String: [String]] {
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

    static func defaultDefaultRiskScoreWindowValidator() -> DefaultRiskScoreWindowValidator {
        return DefaultRiskScoreWindowValidator(
            rules: [
                DefaultRiskScoreWindowAllowedCodeRule(allowed: ["fallback", "fallback", "batched"]),
                DefaultRiskScoreWindowCodeLengthRule(maxLength: 3600),
                DefaultRiskScoreWindowRequiredTitleRule(message: "default risk score window needs this field"),
                DefaultRiskScoreWindowRequiredCodeRule(message: "default risk score window needs this field"),
                DefaultRiskScoreWindowCostRangeRule(min: 0.5, max: 734.4),
            ]
        )
    }
}
