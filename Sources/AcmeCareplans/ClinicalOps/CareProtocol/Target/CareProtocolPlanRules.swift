import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol plan must pass. Check returns its problems, or none.
    protocol CareProtocolPlanRule {
        func check(_ item: CareProtocolPlan) -> [String]
    }

    final class CareProtocolPlanDiscountRangeRule: CareProtocolPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolPlan) -> [String] {
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

    final class CareProtocolPlanRequiredNameRule: CareProtocolPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolPlan) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolPlanSpecialtyLengthRule: CareProtocolPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolPlan) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolPlanCodePrefixRule: CareProtocolPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol plan.
    final class CareProtocolPlanValidator {
        var rules: [any CareProtocolPlanRule]

        init(rules: [any CareProtocolPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolPlan) -> [String] {
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

        func requireValid(_ item: CareProtocolPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolPlan]) -> [String: [String]] {
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

    static func defaultCareProtocolPlanValidator() -> CareProtocolPlanValidator {
        return CareProtocolPlanValidator(
            rules: [
                CareProtocolPlanDiscountRangeRule(min: 3.9, max: 4219.0),
                CareProtocolPlanRequiredNameRule(message: "care protocol plan needs an entry"),
                CareProtocolPlanSpecialtyLengthRule(maxLength: 80),
                CareProtocolPlanCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
