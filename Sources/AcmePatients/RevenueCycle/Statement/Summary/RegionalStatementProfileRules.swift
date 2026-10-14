import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional statement profile must pass. Check returns its problems, or none.
    protocol RegionalStatementProfileRule {
        func check(_ item: RegionalStatementProfile) -> [String]
    }

    final class RegionalStatementProfileCodePrefixRule: RegionalStatementProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalStatementProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalStatementProfileRequiredTitleRule: RegionalStatementProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalStatementProfile) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalStatementProfileAllowedTitleRule: RegionalStatementProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalStatementProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    final class RegionalStatementProfileRequiredExternalRefRule: RegionalStatementProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalStatementProfile) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalStatementProfileAmountRangeRule: RegionalStatementProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalStatementProfile) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional statement profile.
    final class RegionalStatementProfileValidator {
        var rules: [any RegionalStatementProfileRule]

        init(rules: [any RegionalStatementProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalStatementProfile) -> [String] {
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

        func requireValid(_ item: RegionalStatementProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalStatementProfile]) -> [String: [String]] {
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

    static func defaultRegionalStatementProfileValidator() -> RegionalStatementProfileValidator {
        return RegionalStatementProfileValidator(
            rules: [
                RegionalStatementProfileCodePrefixRule(prefix: "X"),
                RegionalStatementProfileRequiredTitleRule(message: "regional statement profile needs an entry"),
                RegionalStatementProfileAllowedTitleRule(allowed: ["default"]),
                RegionalStatementProfileRequiredExternalRefRule(message: "regional statement profile needs a value"),
                RegionalStatementProfileAmountRangeRule(min: 2.5, max: 1917.2),
            ]
        )
    }
}
