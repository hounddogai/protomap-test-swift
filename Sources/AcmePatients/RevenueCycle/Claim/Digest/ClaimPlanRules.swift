import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim plan must pass. Check returns its problems, or none.
    protocol ClaimPlanRule {
        func check(_ item: ClaimPlan) -> [String]
    }

    final class ClaimPlanSpecialtyLengthRule: ClaimPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimPlan) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimPlanRequiredLabelRule: ClaimPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimPlan) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimPlanFloorValueRangeRule: ClaimPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimPlan) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimPlanCodePrefixRule: ClaimPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClaimPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim plan.
    final class ClaimPlanValidator {
        var rules: [any ClaimPlanRule]

        init(rules: [any ClaimPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimPlan]) -> [String: [String]] {
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

    static func defaultClaimPlanValidator() -> ClaimPlanValidator {
        return ClaimPlanValidator(
            rules: [
                ClaimPlanSpecialtyLengthRule(maxLength: 80),
                ClaimPlanRequiredLabelRule(message: "claim plan needs this field"),
                ClaimPlanFloorValueRangeRule(min: 2.9, max: 1288.3),
                ClaimPlanCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
