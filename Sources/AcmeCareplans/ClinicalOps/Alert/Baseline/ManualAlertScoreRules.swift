import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual alert score must pass. Check returns its problems, or none.
    protocol ManualAlertScoreRule {
        func check(_ item: ManualAlertScore) -> [String]
    }

    final class ManualAlertScoreAllowedCountryRule: ManualAlertScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualAlertScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is missing"]
            }
            return []
        }
    }

    final class ManualAlertScoreRequiredCountryRule: ManualAlertScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAlertScore) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualAlertScoreMarginRangeRule: ManualAlertScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualAlertScore) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualAlertScoreCodePrefixRule: ManualAlertScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualAlertScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual alert score.
    final class ManualAlertScoreValidator {
        var rules: [any ManualAlertScoreRule]

        init(rules: [any ManualAlertScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualAlertScore) -> [String] {
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

        func requireValid(_ item: ManualAlertScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualAlertScore]) -> [String: [String]] {
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

    static func defaultManualAlertScoreValidator() -> ManualAlertScoreValidator {
        return ManualAlertScoreValidator(
            rules: [
                ManualAlertScoreAllowedCountryRule(allowed: ["primary"]),
                ManualAlertScoreRequiredCountryRule(message: "manual alert score needs an entry"),
                ManualAlertScoreMarginRangeRule(min: 7.0, max: 2860.4),
                ManualAlertScoreCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
