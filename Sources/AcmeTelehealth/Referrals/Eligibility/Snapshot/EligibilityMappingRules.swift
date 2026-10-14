import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility mapping must pass. Check returns its problems, or none.
    protocol EligibilityMappingRule {
        func check(_ item: EligibilityMapping) -> [String]
    }

    final class EligibilityMappingWeightRangeRule: EligibilityMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityMapping) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class EligibilityMappingCostRangeRule: EligibilityMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityMapping) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class EligibilityMappingCodeLengthRule: EligibilityMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityMappingRequiredCodeRule: EligibilityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityMappingRequiredReviewerRule: EligibilityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityMapping) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityMappingReviewerLengthRule: EligibilityMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityMapping) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility mapping.
    final class EligibilityMappingValidator {
        var rules: [any EligibilityMappingRule]

        init(rules: [any EligibilityMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityMapping) -> [String] {
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

        func requireValid(_ item: EligibilityMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityMapping]) -> [String: [String]] {
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

    static func defaultEligibilityMappingValidator() -> EligibilityMappingValidator {
        return EligibilityMappingValidator(
            rules: [
                EligibilityMappingWeightRangeRule(min: 7.6, max: 3179.6),
                EligibilityMappingCostRangeRule(min: 7.1, max: 809.0),
                EligibilityMappingCodeLengthRule(maxLength: 3600),
                EligibilityMappingRequiredCodeRule(message: "eligibility mapping needs this field"),
                EligibilityMappingRequiredReviewerRule(message: "eligibility mapping needs a value"),
                EligibilityMappingReviewerLengthRule(maxLength: 255),
            ]
        )
    }
}
