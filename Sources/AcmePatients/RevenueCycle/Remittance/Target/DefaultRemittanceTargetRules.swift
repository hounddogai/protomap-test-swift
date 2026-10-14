import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default remittance target must pass. Check returns its problems, or none.
    protocol DefaultRemittanceTargetRule {
        func check(_ item: DefaultRemittanceTarget) -> [String]
    }

    final class DefaultRemittanceTargetRatioRangeRule: DefaultRemittanceTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRemittanceTarget) -> [String] {
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

    final class DefaultRemittanceTargetPatientRefLengthRule: DefaultRemittanceTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRemittanceTarget) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRemittanceTargetDiscountRangeRule: DefaultRemittanceTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRemittanceTarget) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default remittance target.
    final class DefaultRemittanceTargetValidator {
        var rules: [any DefaultRemittanceTargetRule]

        init(rules: [any DefaultRemittanceTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRemittanceTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultRemittanceTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRemittanceTarget]) -> [String: [String]] {
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

    static func defaultDefaultRemittanceTargetValidator() -> DefaultRemittanceTargetValidator {
        return DefaultRemittanceTargetValidator(
            rules: [
                DefaultRemittanceTargetRatioRangeRule(min: 8.2, max: 4058.7),
                DefaultRemittanceTargetPatientRefLengthRule(maxLength: 3600),
                DefaultRemittanceTargetDiscountRangeRule(min: 6.4, max: 236.9),
            ]
        )
    }
}
