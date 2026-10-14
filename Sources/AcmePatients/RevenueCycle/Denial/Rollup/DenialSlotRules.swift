import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial slot must pass. Check returns its problems, or none.
    protocol DenialSlotRule {
        func check(_ item: DenialSlot) -> [String]
    }

    final class DenialSlotRequiredNotesRule: DenialSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialSlot) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialSlotRequiredClinicianIDRule: DenialSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialSlot) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialSlotRateRangeRule: DenialSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialSlot) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DenialSlotLimitRangeRule: DenialSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialSlot) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DenialSlotRequiredLabelRule: DenialSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialSlot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a denial slot.
    final class DenialSlotValidator {
        var rules: [any DenialSlotRule]

        init(rules: [any DenialSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialSlot]) -> [String: [String]] {
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

    static func defaultDenialSlotValidator() -> DenialSlotValidator {
        return DenialSlotValidator(
            rules: [
                DenialSlotRequiredNotesRule(message: "denial slot needs this field"),
                DenialSlotRequiredClinicianIDRule(message: "denial slot needs an entry"),
                DenialSlotRateRangeRule(min: 7.9, max: 4808.9),
                DenialSlotLimitRangeRule(min: 32, max: 255),
                DenialSlotRequiredLabelRule(message: "denial slot needs an entry"),
            ]
        )
    }
}
