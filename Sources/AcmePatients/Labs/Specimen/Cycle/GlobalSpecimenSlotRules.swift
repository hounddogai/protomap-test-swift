import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global specimen slot must pass. Check returns its problems, or none.
    protocol GlobalSpecimenSlotRule {
        func check(_ item: GlobalSpecimenSlot) -> [String]
    }

    final class GlobalSpecimenSlotCodeLengthRule: GlobalSpecimenSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSpecimenSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSpecimenSlotRequiredTitleRule: GlobalSpecimenSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSpecimenSlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSpecimenSlotCostRangeRule: GlobalSpecimenSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalSpecimenSlot) -> [String] {
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

    final class GlobalSpecimenSlotRateRangeRule: GlobalSpecimenSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalSpecimenSlot) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global specimen slot.
    final class GlobalSpecimenSlotValidator {
        var rules: [any GlobalSpecimenSlotRule]

        init(rules: [any GlobalSpecimenSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSpecimenSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalSpecimenSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSpecimenSlot]) -> [String: [String]] {
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

    static func defaultGlobalSpecimenSlotValidator() -> GlobalSpecimenSlotValidator {
        return GlobalSpecimenSlotValidator(
            rules: [
                GlobalSpecimenSlotCodeLengthRule(maxLength: 64),
                GlobalSpecimenSlotRequiredTitleRule(message: "global specimen slot needs an entry"),
                GlobalSpecimenSlotCostRangeRule(min: 3.6, max: 2897.1),
                GlobalSpecimenSlotRateRangeRule(min: 1.4, max: 1444.9),
            ]
        )
    }
}
