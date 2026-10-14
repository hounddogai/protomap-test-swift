import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict bed board cycle must pass. Check returns its problems, or none.
    protocol StrictBedBoardCycleRule {
        func check(_ item: StrictBedBoardCycle) -> [String]
    }

    final class StrictBedBoardCycleRequiredNameRule: StrictBedBoardCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictBedBoardCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictBedBoardCycleNameLengthRule: StrictBedBoardCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictBedBoardCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictBedBoardCyclePatientRefLengthRule: StrictBedBoardCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictBedBoardCycle) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictBedBoardCycleCeilingRangeRule: StrictBedBoardCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictBedBoardCycle) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictBedBoardCycleRequiredCodeRule: StrictBedBoardCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictBedBoardCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictBedBoardCyclePinnedGuardRule: StrictBedBoardCycleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictBedBoardCycle) -> [String] {
            if item.pinned && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a strict bed board cycle.
    final class StrictBedBoardCycleValidator {
        var rules: [any StrictBedBoardCycleRule]

        init(rules: [any StrictBedBoardCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictBedBoardCycle) -> [String] {
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

        func requireValid(_ item: StrictBedBoardCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictBedBoardCycle]) -> [String: [String]] {
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

    static func defaultStrictBedBoardCycleValidator() -> StrictBedBoardCycleValidator {
        return StrictBedBoardCycleValidator(
            rules: [
                StrictBedBoardCycleRequiredNameRule(message: "strict bed board cycle needs this field"),
                StrictBedBoardCycleNameLengthRule(maxLength: 255),
                StrictBedBoardCyclePatientRefLengthRule(maxLength: 64),
                StrictBedBoardCycleCeilingRangeRule(min: 1.3, max: 2048.8),
                StrictBedBoardCycleRequiredCodeRule(message: "strict bed board cycle needs this field"),
                StrictBedBoardCyclePinnedGuardRule(limit: 255),
            ]
        )
    }
}
