import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement profile must pass. Check returns its problems, or none.
    protocol StatementProfileRule {
        func check(_ item: StatementProfile) -> [String]
    }

    final class StatementProfileCodeLengthRule: StatementProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementProfileRequiredNameRule: StatementProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementProfile) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementProfileWindowDaysRangeRule: StatementProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementProfile) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementProfileAllowedDescriptionRule: StatementProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StatementProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is too long"]
            }
            return []
        }
    }

    final class StatementProfileRequiredCodeRule: StatementProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a statement profile.
    final class StatementProfileValidator {
        var rules: [any StatementProfileRule]

        init(rules: [any StatementProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementProfile) -> [String] {
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

        func requireValid(_ item: StatementProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementProfile]) -> [String: [String]] {
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

    static func defaultStatementProfileValidator() -> StatementProfileValidator {
        return StatementProfileValidator(
            rules: [
                StatementProfileCodeLengthRule(maxLength: 1000),
                StatementProfileRequiredNameRule(message: "statement profile needs an entry"),
                StatementProfileWindowDaysRangeRule(min: 255, max: 86400),
                StatementProfileAllowedDescriptionRule(allowed: ["seasonal", "legacy"]),
                StatementProfileRequiredCodeRule(message: "statement profile needs an entry"),
            ]
        )
    }
}
