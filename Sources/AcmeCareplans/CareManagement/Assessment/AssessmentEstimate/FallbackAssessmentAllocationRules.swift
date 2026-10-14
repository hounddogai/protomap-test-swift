import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback assessment allocation must pass. Check returns its problems, or none.
    protocol FallbackAssessmentAllocationRule {
        func check(_ item: FallbackAssessmentAllocation) -> [String]
    }

    final class FallbackAssessmentAllocationNameLengthRule: FallbackAssessmentAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAssessmentAllocation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAssessmentAllocationRequiredNameRule: FallbackAssessmentAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAssessmentAllocation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAssessmentAllocationCodeLengthRule: FallbackAssessmentAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAssessmentAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAssessmentAllocationDiscountRangeRule: FallbackAssessmentAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackAssessmentAllocation) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackAssessmentAllocationAllowedCodeRule: FallbackAssessmentAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackAssessmentAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback assessment allocation.
    final class FallbackAssessmentAllocationValidator {
        var rules: [any FallbackAssessmentAllocationRule]

        init(rules: [any FallbackAssessmentAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackAssessmentAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackAssessmentAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackAssessmentAllocation]) -> [String: [String]] {
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

    static func defaultFallbackAssessmentAllocationValidator() -> FallbackAssessmentAllocationValidator {
        return FallbackAssessmentAllocationValidator(
            rules: [
                FallbackAssessmentAllocationNameLengthRule(maxLength: 3600),
                FallbackAssessmentAllocationRequiredNameRule(message: "fallback assessment allocation needs a value"),
                FallbackAssessmentAllocationCodeLengthRule(maxLength: 3600),
                FallbackAssessmentAllocationDiscountRangeRule(min: 7.8, max: 4521.5),
                FallbackAssessmentAllocationAllowedCodeRule(allowed: ["lenient"]),
            ]
        )
    }
}
