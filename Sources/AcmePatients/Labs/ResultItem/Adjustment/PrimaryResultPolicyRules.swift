import AcmePlatform
import Foundation

extension Labs {
    /// A rule a primary result policy must pass. Check returns its problems, or none.
    protocol PrimaryResultPolicyRule {
        func check(_ item: PrimaryResultPolicy) -> [String]
    }

    final class PrimaryResultPolicyBedLengthRule: PrimaryResultPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryResultPolicy) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryResultPolicyEndsAtRangeRule: PrimaryResultPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryResultPolicy) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryResultPolicyRequiredLocaleRule: PrimaryResultPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryResultPolicy) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary result policy.
    final class PrimaryResultPolicyValidator {
        var rules: [any PrimaryResultPolicyRule]

        init(rules: [any PrimaryResultPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryResultPolicy) -> [String] {
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

        func requireValid(_ item: PrimaryResultPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryResultPolicy]) -> [String: [String]] {
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

    static func defaultPrimaryResultPolicyValidator() -> PrimaryResultPolicyValidator {
        return PrimaryResultPolicyValidator(
            rules: [
                PrimaryResultPolicyBedLengthRule(maxLength: 80),
                PrimaryResultPolicyEndsAtRangeRule(min: 32, max: 3600),
                PrimaryResultPolicyRequiredLocaleRule(message: "primary result policy needs an entry"),
            ]
        )
    }
}
