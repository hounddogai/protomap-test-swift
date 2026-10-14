import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional authorization allocation must pass. Check returns its problems, or none.
    protocol RegionalAuthorizationAllocationRule {
        func check(_ item: RegionalAuthorizationAllocation) -> [String]
    }

    final class RegionalAuthorizationAllocationWardLengthRule: RegionalAuthorizationAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAuthorizationAllocation) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalAuthorizationAllocationDurationMinutesRangeRule: RegionalAuthorizationAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAuthorizationAllocation) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalAuthorizationAllocationLabelLengthRule: RegionalAuthorizationAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAuthorizationAllocation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalAuthorizationAllocationRequiredLabelRule: RegionalAuthorizationAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAuthorizationAllocation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalAuthorizationAllocationCodeLengthRule: RegionalAuthorizationAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAuthorizationAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalAuthorizationAllocationRequiredCodeRule: RegionalAuthorizationAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAuthorizationAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional authorization allocation.
    final class RegionalAuthorizationAllocationValidator {
        var rules: [any RegionalAuthorizationAllocationRule]

        init(rules: [any RegionalAuthorizationAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalAuthorizationAllocation) -> [String] {
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

        func requireValid(_ item: RegionalAuthorizationAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalAuthorizationAllocation]) -> [String: [String]] {
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

    static func defaultRegionalAuthorizationAllocationValidator() -> RegionalAuthorizationAllocationValidator {
        return RegionalAuthorizationAllocationValidator(
            rules: [
                RegionalAuthorizationAllocationWardLengthRule(maxLength: 80),
                RegionalAuthorizationAllocationDurationMinutesRangeRule(min: 32, max: 255),
                RegionalAuthorizationAllocationLabelLengthRule(maxLength: 120),
                RegionalAuthorizationAllocationRequiredLabelRule(
                    message: "regional authorization allocation needs an entry"
                ),
                RegionalAuthorizationAllocationCodeLengthRule(maxLength: 64),
                RegionalAuthorizationAllocationRequiredCodeRule(
                    message: "regional authorization allocation needs an entry"
                ),
            ]
        )
    }
}
