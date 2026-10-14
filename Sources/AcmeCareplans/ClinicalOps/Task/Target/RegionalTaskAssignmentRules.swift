import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional task assignment must pass. Check returns its problems, or none.
    protocol RegionalTaskAssignmentRule {
        func check(_ item: RegionalTaskAssignment) -> [String]
    }

    final class RegionalTaskAssignmentChannelLengthRule: RegionalTaskAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalTaskAssignment) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalTaskAssignmentRequiredCurrencyRule: RegionalTaskAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalTaskAssignment) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalTaskAssignmentAllowedChannelRule: RegionalTaskAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalTaskAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is blocked"]
            }
            return []
        }
    }

    final class RegionalTaskAssignmentCostRangeRule: RegionalTaskAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalTaskAssignment) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional task assignment.
    final class RegionalTaskAssignmentValidator {
        var rules: [any RegionalTaskAssignmentRule]

        init(rules: [any RegionalTaskAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalTaskAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalTaskAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalTaskAssignment]) -> [String: [String]] {
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

    static func defaultRegionalTaskAssignmentValidator() -> RegionalTaskAssignmentValidator {
        return RegionalTaskAssignmentValidator(
            rules: [
                RegionalTaskAssignmentChannelLengthRule(maxLength: 16),
                RegionalTaskAssignmentRequiredCurrencyRule(message: "regional task assignment needs a value"),
                RegionalTaskAssignmentAllowedChannelRule(allowed: ["adaptive"]),
                RegionalTaskAssignmentCostRangeRule(min: 1.4, max: 4506.1),
            ]
        )
    }
}
