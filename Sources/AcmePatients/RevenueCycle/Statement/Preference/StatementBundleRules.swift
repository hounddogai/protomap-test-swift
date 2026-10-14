import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement bundle must pass. Check returns its problems, or none.
    protocol StatementBundleRule {
        func check(_ item: StatementBundle) -> [String]
    }

    final class StatementBundleRequiredNameRule: StatementBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementBundleTimezoneLengthRule: StatementBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementBundle) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementBundleNameLengthRule: StatementBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementBundleLimitRangeRule: StatementBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementBundle) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementBundleCodeLengthRule: StatementBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement bundle.
    final class StatementBundleValidator {
        var rules: [any StatementBundleRule]

        init(rules: [any StatementBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementBundle) -> [String] {
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

        func requireValid(_ item: StatementBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementBundle]) -> [String: [String]] {
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

    static func defaultStatementBundleValidator() -> StatementBundleValidator {
        return StatementBundleValidator(
            rules: [
                StatementBundleRequiredNameRule(message: "statement bundle needs a value"),
                StatementBundleTimezoneLengthRule(maxLength: 16),
                StatementBundleNameLengthRule(maxLength: 80),
                StatementBundleLimitRangeRule(min: 1000, max: 1000),
                StatementBundleCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
