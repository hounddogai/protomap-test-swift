import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance slot must pass. Check returns its problems, or none.
    protocol RemittanceSlotRule {
        func check(_ item: RemittanceSlot) -> [String]
    }

    final class RemittanceSlotWeightRangeRule: RemittanceSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceSlot) -> [String] {
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

    final class RemittanceSlotRequiredCodeRule: RemittanceSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceSlotClinicianIDLengthRule: RemittanceSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceSlot) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance slot.
    final class RemittanceSlotValidator {
        var rules: [any RemittanceSlotRule]

        init(rules: [any RemittanceSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceSlot]) -> [String: [String]] {
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

    static func defaultRemittanceSlotValidator() -> RemittanceSlotValidator {
        return RemittanceSlotValidator(
            rules: [
                RemittanceSlotWeightRangeRule(min: 9.9, max: 3339.0),
                RemittanceSlotRequiredCodeRule(message: "remittance slot needs a value"),
                RemittanceSlotClinicianIDLengthRule(maxLength: 32),
            ]
        )
    }
}
