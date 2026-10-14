import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan slot must pass. Check returns its problems, or none.
    protocol AcuityPlanSlotRule {
        func check(_ item: AcuityPlanSlot) -> [String]
    }

    final class AcuityPlanSlotRequiredLabelRule: AcuityPlanSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanSlot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanSlotRefillsRangeRule: AcuityPlanSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanSlot) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanSlotExternalRefLengthRule: AcuityPlanSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanSlot) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanSlotLabelLengthRule: AcuityPlanSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanSlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanSlotWeightRangeRule: AcuityPlanSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanSlot) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanSlotTitleLengthRule: AcuityPlanSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanSlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan slot.
    final class AcuityPlanSlotValidator {
        var rules: [any AcuityPlanSlotRule]

        init(rules: [any AcuityPlanSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanSlot) -> [String] {
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

        func requireValid(_ item: AcuityPlanSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanSlot]) -> [String: [String]] {
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

    static func defaultAcuityPlanSlotValidator() -> AcuityPlanSlotValidator {
        return AcuityPlanSlotValidator(
            rules: [
                AcuityPlanSlotRequiredLabelRule(message: "acuity plan slot needs a value"),
                AcuityPlanSlotRefillsRangeRule(min: 32, max: 32),
                AcuityPlanSlotExternalRefLengthRule(maxLength: 3600),
                AcuityPlanSlotLabelLengthRule(maxLength: 1000),
                AcuityPlanSlotWeightRangeRule(min: 8.3, max: 458.6),
                AcuityPlanSlotTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
