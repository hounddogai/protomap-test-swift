import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual remittance adjustment must pass. Check returns its problems, or none.
    protocol ManualRemittanceAdjustmentRule {
        func check(_ item: ManualRemittanceAdjustment) -> [String]
    }

    final class ManualRemittanceAdjustmentAmountRangeRule: ManualRemittanceAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRemittanceAdjustment) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualRemittanceAdjustmentRequiredFacilityRule: ManualRemittanceAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRemittanceAdjustment) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRemittanceAdjustmentUnitLengthRule: ManualRemittanceAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRemittanceAdjustment) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRemittanceAdjustmentNameLengthRule: ManualRemittanceAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRemittanceAdjustment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual remittance adjustment.
    final class ManualRemittanceAdjustmentValidator {
        var rules: [any ManualRemittanceAdjustmentRule]

        init(rules: [any ManualRemittanceAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRemittanceAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualRemittanceAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRemittanceAdjustment]) -> [String: [String]] {
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

    static func defaultManualRemittanceAdjustmentValidator() -> ManualRemittanceAdjustmentValidator {
        return ManualRemittanceAdjustmentValidator(
            rules: [
                ManualRemittanceAdjustmentAmountRangeRule(min: 1.5, max: 1559.8),
                ManualRemittanceAdjustmentRequiredFacilityRule(
                    message: "manual remittance adjustment needs this field"
                ),
                ManualRemittanceAdjustmentUnitLengthRule(maxLength: 16),
                ManualRemittanceAdjustmentNameLengthRule(maxLength: 1000),
            ]
        )
    }
}
