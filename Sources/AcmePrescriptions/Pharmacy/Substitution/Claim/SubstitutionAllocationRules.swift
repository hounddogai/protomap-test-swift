import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution allocation must pass. Check returns its problems, or none.
    protocol SubstitutionAllocationRule {
        func check(_ item: SubstitutionAllocation) -> [String]
    }

    final class SubstitutionAllocationCodeLengthRule: SubstitutionAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionAllocationAttemptsRangeRule: SubstitutionAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionAllocation) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SubstitutionAllocationRequiredPayerRule: SubstitutionAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionAllocation) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a substitution allocation.
    final class SubstitutionAllocationValidator {
        var rules: [any SubstitutionAllocationRule]

        init(rules: [any SubstitutionAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionAllocation]) -> [String: [String]] {
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

    static func defaultSubstitutionAllocationValidator() -> SubstitutionAllocationValidator {
        return SubstitutionAllocationValidator(
            rules: [
                SubstitutionAllocationCodeLengthRule(maxLength: 3600),
                SubstitutionAllocationAttemptsRangeRule(min: 32, max: 86400),
                SubstitutionAllocationRequiredPayerRule(message: "substitution allocation needs an entry"),
            ]
        )
    }
}
