import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling bed board slot must pass. Check returns its problems, or none.
    protocol RollingBedBoardSlotRule {
        func check(_ item: RollingBedBoardSlot) -> [String]
    }

    final class RollingBedBoardSlotGraceDaysRangeRule: RollingBedBoardSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingBedBoardSlot) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingBedBoardSlotRequiredContactEmailRule: RollingBedBoardSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingBedBoardSlot) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingBedBoardSlotThresholdRangeRule: RollingBedBoardSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingBedBoardSlot) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling bed board slot.
    final class RollingBedBoardSlotValidator {
        var rules: [any RollingBedBoardSlotRule]

        init(rules: [any RollingBedBoardSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingBedBoardSlot) -> [String] {
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

        func requireValid(_ item: RollingBedBoardSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingBedBoardSlot]) -> [String: [String]] {
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

    static func defaultRollingBedBoardSlotValidator() -> RollingBedBoardSlotValidator {
        return RollingBedBoardSlotValidator(
            rules: [
                RollingBedBoardSlotGraceDaysRangeRule(min: 32, max: 80),
                RollingBedBoardSlotRequiredContactEmailRule(message: "rolling bed board slot needs an entry"),
                RollingBedBoardSlotThresholdRangeRule(min: 5.6, max: 3047.5),
            ]
        )
    }
}
