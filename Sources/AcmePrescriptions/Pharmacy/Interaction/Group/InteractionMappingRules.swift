import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction mapping must pass. Check returns its problems, or none.
    protocol InteractionMappingRule {
        func check(_ item: InteractionMapping) -> [String]
    }

    final class InteractionMappingGraceDaysRangeRule: InteractionMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionMapping) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionMappingRequiredTitleRule: InteractionMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionMappingEndsAtRangeRule: InteractionMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionMapping) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction mapping.
    final class InteractionMappingValidator {
        var rules: [any InteractionMappingRule]

        init(rules: [any InteractionMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionMapping]) -> [String: [String]] {
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

    static func defaultInteractionMappingValidator() -> InteractionMappingValidator {
        return InteractionMappingValidator(
            rules: [
                InteractionMappingGraceDaysRangeRule(min: 16, max: 86400),
                InteractionMappingRequiredTitleRule(message: "interaction mapping needs this field"),
                InteractionMappingEndsAtRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
