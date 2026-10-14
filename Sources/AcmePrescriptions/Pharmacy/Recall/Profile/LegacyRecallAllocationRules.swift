import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy recall allocation must pass. Check returns its problems, or none.
    protocol LegacyRecallAllocationRule {
        func check(_ item: LegacyRecallAllocation) -> [String]
    }

    final class LegacyRecallAllocationWindowDaysRangeRule: LegacyRecallAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyRecallAllocation) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyRecallAllocationRequiredNotesRule: LegacyRecallAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRecallAllocation) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRecallAllocationNotesLengthRule: LegacyRecallAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRecallAllocation) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy recall allocation.
    final class LegacyRecallAllocationValidator {
        var rules: [any LegacyRecallAllocationRule]

        init(rules: [any LegacyRecallAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyRecallAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyRecallAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyRecallAllocation]) -> [String: [String]] {
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

    static func defaultLegacyRecallAllocationValidator() -> LegacyRecallAllocationValidator {
        return LegacyRecallAllocationValidator(
            rules: [
                LegacyRecallAllocationWindowDaysRangeRule(min: 16, max: 120),
                LegacyRecallAllocationRequiredNotesRule(message: "legacy recall allocation needs a value"),
                LegacyRecallAllocationNotesLengthRule(maxLength: 80),
            ]
        )
    }
}
