import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional statement baseline must pass. Check returns its problems, or none.
    protocol RegionalStatementBaselineRule {
        func check(_ item: RegionalStatementBaseline) -> [String]
    }

    final class RegionalStatementBaselineAllowedWardRule: RegionalStatementBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalStatementBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is out of range"]
            }
            return []
        }
    }

    final class RegionalStatementBaselineWardLengthRule: RegionalStatementBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalStatementBaseline) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalStatementBaselineRequiredCodeRule: RegionalStatementBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalStatementBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalStatementBaselineLabelLengthRule: RegionalStatementBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalStatementBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional statement baseline.
    final class RegionalStatementBaselineValidator {
        var rules: [any RegionalStatementBaselineRule]

        init(rules: [any RegionalStatementBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalStatementBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalStatementBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalStatementBaseline]) -> [String: [String]] {
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

    static func defaultRegionalStatementBaselineValidator() -> RegionalStatementBaselineValidator {
        return RegionalStatementBaselineValidator(
            rules: [
                RegionalStatementBaselineAllowedWardRule(allowed: []),
                RegionalStatementBaselineWardLengthRule(maxLength: 80),
                RegionalStatementBaselineRequiredCodeRule(message: "regional statement baseline needs an entry"),
                RegionalStatementBaselineLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
