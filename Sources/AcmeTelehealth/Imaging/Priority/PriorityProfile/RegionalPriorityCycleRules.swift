import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional priority cycle must pass. Check returns its problems, or none.
    protocol RegionalPriorityCycleRule {
        func check(_ item: RegionalPriorityCycle) -> [String]
    }

    final class RegionalPriorityCycleRequiredExternalRefRule: RegionalPriorityCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalPriorityCycle) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalPriorityCycleRequiredLabelRule: RegionalPriorityCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalPriorityCycle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalPriorityCycleRequiredCodeRule: RegionalPriorityCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalPriorityCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalPriorityCycleCapacityRangeRule: RegionalPriorityCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalPriorityCycle) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalPriorityCycleAllowedProcedureCodeRule: RegionalPriorityCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalPriorityCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is not allowed"]
            }
            return []
        }
    }

    final class RegionalPriorityCycleLabelLengthRule: RegionalPriorityCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalPriorityCycle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional priority cycle.
    final class RegionalPriorityCycleValidator {
        var rules: [any RegionalPriorityCycleRule]

        init(rules: [any RegionalPriorityCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalPriorityCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalPriorityCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalPriorityCycle]) -> [String: [String]] {
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

    static func defaultRegionalPriorityCycleValidator() -> RegionalPriorityCycleValidator {
        return RegionalPriorityCycleValidator(
            rules: [
                RegionalPriorityCycleRequiredExternalRefRule(message: "regional priority cycle needs a value"),
                RegionalPriorityCycleRequiredLabelRule(message: "regional priority cycle needs a value"),
                RegionalPriorityCycleRequiredCodeRule(message: "regional priority cycle needs an entry"),
                RegionalPriorityCycleCapacityRangeRule(min: 255, max: 1000),
                RegionalPriorityCycleAllowedProcedureCodeRule(allowed: []),
                RegionalPriorityCycleLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
