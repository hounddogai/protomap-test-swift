import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement allocation must pass. Check returns its problems, or none.
    protocol StatementAllocationRule {
        func check(_ item: StatementAllocation) -> [String]
    }

    final class StatementAllocationRequiredContactEmailRule: StatementAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementAllocation) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementAllocationScoreRangeRule: StatementAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementAllocation) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementAllocationAllowedContactEmailRule: StatementAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StatementAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is not allowed"]
            }
            return []
        }
    }

    final class StatementAllocationCodePrefixRule: StatementAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StatementAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StatementAllocationContactEmailLengthRule: StatementAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementAllocation) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement allocation.
    final class StatementAllocationValidator {
        var rules: [any StatementAllocationRule]

        init(rules: [any StatementAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementAllocation]) -> [String: [String]] {
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

    static func defaultStatementAllocationValidator() -> StatementAllocationValidator {
        return StatementAllocationValidator(
            rules: [
                StatementAllocationRequiredContactEmailRule(message: "statement allocation needs this field"),
                StatementAllocationScoreRangeRule(min: 4.8, max: 2364.6),
                StatementAllocationAllowedContactEmailRule(allowed: []),
                StatementAllocationCodePrefixRule(prefix: "OPS"),
                StatementAllocationContactEmailLengthRule(maxLength: 120),
            ]
        )
    }
}
