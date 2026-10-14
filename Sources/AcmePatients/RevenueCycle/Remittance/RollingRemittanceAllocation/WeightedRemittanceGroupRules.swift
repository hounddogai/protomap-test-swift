import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted remittance group must pass. Check returns its problems, or none.
    protocol WeightedRemittanceGroupRule {
        func check(_ item: WeightedRemittanceGroup) -> [String]
    }

    final class WeightedRemittanceGroupRequiredAllergyRule: WeightedRemittanceGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRemittanceGroup) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRemittanceGroupLabelLengthRule: WeightedRemittanceGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRemittanceGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRemittanceGroupRequiredCodeRule: WeightedRemittanceGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRemittanceGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRemittanceGroupAllergyLengthRule: WeightedRemittanceGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRemittanceGroup) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRemittanceGroupRatioRangeRule: WeightedRemittanceGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedRemittanceGroup) -> [String] {
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

    final class WeightedRemittanceGroupCodeLengthRule: WeightedRemittanceGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRemittanceGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted remittance group.
    final class WeightedRemittanceGroupValidator {
        var rules: [any WeightedRemittanceGroupRule]

        init(rules: [any WeightedRemittanceGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRemittanceGroup) -> [String] {
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

        func requireValid(_ item: WeightedRemittanceGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRemittanceGroup]) -> [String: [String]] {
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

    static func defaultWeightedRemittanceGroupValidator() -> WeightedRemittanceGroupValidator {
        return WeightedRemittanceGroupValidator(
            rules: [
                WeightedRemittanceGroupRequiredAllergyRule(message: "weighted remittance group needs a value"),
                WeightedRemittanceGroupLabelLengthRule(maxLength: 86400),
                WeightedRemittanceGroupRequiredCodeRule(message: "weighted remittance group needs this field"),
                WeightedRemittanceGroupAllergyLengthRule(maxLength: 1000),
                WeightedRemittanceGroupRatioRangeRule(min: 3.7, max: 51.0),
                WeightedRemittanceGroupCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
