import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement digest must pass. Check returns its problems, or none.
    protocol StatementDigestRule {
        func check(_ item: StatementDigest) -> [String]
    }

    final class StatementDigestRequiredPhoneRule: StatementDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementDigest) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementDigestAllowedPayerRule: StatementDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StatementDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is out of range"]
            }
            return []
        }
    }

    final class StatementDigestLabelLengthRule: StatementDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementDigest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementDigestStartsAtRangeRule: StatementDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementDigest) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementDigestVersionRangeRule: StatementDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementDigest) -> [String] {
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

    /// Runs every rule of a statement digest.
    final class StatementDigestValidator {
        var rules: [any StatementDigestRule]

        init(rules: [any StatementDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementDigest]) -> [String: [String]] {
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

    static func defaultStatementDigestValidator() -> StatementDigestValidator {
        return StatementDigestValidator(
            rules: [
                StatementDigestRequiredPhoneRule(message: "statement digest needs an entry"),
                StatementDigestAllowedPayerRule(allowed: ["seasonal"]),
                StatementDigestLabelLengthRule(maxLength: 86400),
                StatementDigestStartsAtRangeRule(min: 3600, max: 3600),
                StatementDigestVersionRangeRule(min: 64, max: 3600),
            ]
        )
    }
}
