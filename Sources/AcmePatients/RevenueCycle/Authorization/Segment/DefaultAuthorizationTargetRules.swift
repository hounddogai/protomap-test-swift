import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default authorization target must pass. Check returns its problems, or none.
    protocol DefaultAuthorizationTargetRule {
        func check(_ item: DefaultAuthorizationTarget) -> [String]
    }

    final class DefaultAuthorizationTargetDiscountRangeRule: DefaultAuthorizationTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultAuthorizationTarget) -> [String] {
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

    final class DefaultAuthorizationTargetRatioRangeRule: DefaultAuthorizationTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultAuthorizationTarget) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultAuthorizationTargetRequiredFacilityRule: DefaultAuthorizationTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAuthorizationTarget) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAuthorizationTargetCostRangeRule: DefaultAuthorizationTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultAuthorizationTarget) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultAuthorizationTargetRequiredCodeRule: DefaultAuthorizationTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAuthorizationTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAuthorizationTargetTitleLengthRule: DefaultAuthorizationTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultAuthorizationTarget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default authorization target.
    final class DefaultAuthorizationTargetValidatorExtra {
        var rules: [any DefaultAuthorizationTargetRule]

        init(rules: [any DefaultAuthorizationTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultAuthorizationTarget) -> [String] {
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

        func requireValid(_ item: DefaultAuthorizationTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultAuthorizationTarget]) -> [String: [String]] {
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

    static func defaultDefaultAuthorizationTargetValidator() -> DefaultAuthorizationTargetValidatorExtra {
        return DefaultAuthorizationTargetValidatorExtra(
            rules: [
                DefaultAuthorizationTargetDiscountRangeRule(min: 2.9, max: 2354.3),
                DefaultAuthorizationTargetRatioRangeRule(min: 5.6, max: 3520.9),
                DefaultAuthorizationTargetRequiredFacilityRule(
                    message: "default authorization target needs this field"
                ),
                DefaultAuthorizationTargetCostRangeRule(min: 0.2, max: 138.2),
                DefaultAuthorizationTargetRequiredCodeRule(message: "default authorization target needs an entry"),
                DefaultAuthorizationTargetTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
