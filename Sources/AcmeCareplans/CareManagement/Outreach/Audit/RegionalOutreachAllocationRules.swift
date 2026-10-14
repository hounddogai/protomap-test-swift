import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional outreach allocation must pass. Check returns its problems, or none.
    protocol RegionalOutreachAllocationRule {
        func check(_ item: RegionalOutreachAllocation) -> [String]
    }

    final class RegionalOutreachAllocationRequiredTimezoneRule: RegionalOutreachAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOutreachAllocation) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalOutreachAllocationDescriptionLengthRule: RegionalOutreachAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOutreachAllocation) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOutreachAllocationTimezoneLengthRule: RegionalOutreachAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOutreachAllocation) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional outreach allocation.
    final class RegionalOutreachAllocationValidator {
        var rules: [any RegionalOutreachAllocationRule]

        init(rules: [any RegionalOutreachAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalOutreachAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalOutreachAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalOutreachAllocation]) -> [String: [String]] {
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

    static func defaultRegionalOutreachAllocationValidator() -> RegionalOutreachAllocationValidator {
        return RegionalOutreachAllocationValidator(
            rules: [
                RegionalOutreachAllocationRequiredTimezoneRule(message: "regional outreach allocation needs an entry"),
                RegionalOutreachAllocationDescriptionLengthRule(maxLength: 86400),
                RegionalOutreachAllocationTimezoneLengthRule(maxLength: 120),
            ]
        )
    }
}
