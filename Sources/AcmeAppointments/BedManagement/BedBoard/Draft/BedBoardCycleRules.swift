import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board cycle must pass. Check returns its problems, or none.
    protocol BedBoardCycleRule {
        func check(_ item: BedBoardCycle) -> [String]
    }

    final class BedBoardCycleRegionLengthRule: BedBoardCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardCycle) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardCycleRequiredCodeRule: BedBoardCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardCycleRequiredRegionRule: BedBoardCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardCycle) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardCycleExpiresAtRangeRule: BedBoardCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardCycle) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BedBoardCycleRequiredNotesRule: BedBoardCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardCycle) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardCycleCodeLengthRule: BedBoardCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board cycle.
    final class BedBoardCycleValidator {
        var rules: [any BedBoardCycleRule]

        init(rules: [any BedBoardCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardCycle]) -> [String: [String]] {
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

    static func defaultBedBoardCycleValidator() -> BedBoardCycleValidator {
        return BedBoardCycleValidator(
            rules: [
                BedBoardCycleRegionLengthRule(maxLength: 32),
                BedBoardCycleRequiredCodeRule(message: "bed board cycle needs an entry"),
                BedBoardCycleRequiredRegionRule(message: "bed board cycle needs a value"),
                BedBoardCycleExpiresAtRangeRule(min: 16, max: 255),
                BedBoardCycleRequiredNotesRule(message: "bed board cycle needs a value"),
                BedBoardCycleCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
