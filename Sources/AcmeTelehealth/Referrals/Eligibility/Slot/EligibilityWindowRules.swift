import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility window must pass. Check returns its problems, or none.
    protocol EligibilityWindowRule {
        func check(_ item: EligibilityWindow) -> [String]
    }

    final class EligibilityWindowAmountRangeRule: EligibilityWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityWindow) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class EligibilityWindowCodePrefixRule: EligibilityWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class EligibilityWindowRequiredWardRule: EligibilityWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityWindow) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility window.
    final class EligibilityWindowValidator {
        var rules: [any EligibilityWindowRule]

        init(rules: [any EligibilityWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityWindow]) -> [String: [String]] {
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

    static func defaultEligibilityWindowValidator() -> EligibilityWindowValidator {
        return EligibilityWindowValidator(
            rules: [
                EligibilityWindowAmountRangeRule(min: 8.8, max: 2352.2),
                EligibilityWindowCodePrefixRule(prefix: "REF"),
                EligibilityWindowRequiredWardRule(message: "eligibility window needs an entry"),
            ]
        )
    }
}
