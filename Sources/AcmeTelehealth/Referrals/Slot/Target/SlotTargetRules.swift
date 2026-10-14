import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot target must pass. Check returns its problems, or none.
    protocol SlotTargetRule {
        func check(_ item: SlotTarget) -> [String]
    }

    final class SlotTargetWindowDaysRangeRule: SlotTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotTarget) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SlotTargetRequiredCodeRule: SlotTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotTargetQuantityRangeRule: SlotTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotTarget) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotTargetRequiredDiagnosisCodeRule: SlotTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotTarget) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a slot target.
    final class SlotTargetValidator {
        var rules: [any SlotTargetRule]

        init(rules: [any SlotTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotTarget]) -> [String: [String]] {
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

    static func defaultSlotTargetValidator() -> SlotTargetValidator {
        return SlotTargetValidator(
            rules: [
                SlotTargetWindowDaysRangeRule(min: 32, max: 120),
                SlotTargetRequiredCodeRule(message: "slot target needs a value"),
                SlotTargetQuantityRangeRule(min: 32, max: 64),
                SlotTargetRequiredDiagnosisCodeRule(message: "slot target needs an entry"),
            ]
        )
    }
}
