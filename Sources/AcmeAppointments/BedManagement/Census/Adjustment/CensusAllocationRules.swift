import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census allocation must pass. Check returns its problems, or none.
    protocol CensusAllocationRule {
        func check(_ item: CensusAllocation) -> [String]
    }

    final class CensusAllocationPinnedGuardRule: CensusAllocationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CensusAllocation) -> [String] {
            if item.pinned && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class CensusAllocationGraceDaysRangeRule: CensusAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusAllocation) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CensusAllocationCodeLengthRule: CensusAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusAllocationWindowDaysRangeRule: CensusAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusAllocation) -> [String] {
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

    /// Runs every rule of a census allocation.
    final class CensusAllocationValidator {
        var rules: [any CensusAllocationRule]

        init(rules: [any CensusAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusAllocation) -> [String] {
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

        func requireValid(_ item: CensusAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusAllocation]) -> [String: [String]] {
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

    static func defaultCensusAllocationValidator() -> CensusAllocationValidator {
        return CensusAllocationValidator(
            rules: [
                CensusAllocationPinnedGuardRule(limit: 255),
                CensusAllocationGraceDaysRangeRule(min: 80, max: 86400),
                CensusAllocationCodeLengthRule(maxLength: 80),
                CensusAllocationWindowDaysRangeRule(min: 32, max: 1000),
            ]
        )
    }
}
