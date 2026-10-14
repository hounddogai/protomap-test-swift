import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped specimen cycle must pass. Check returns its problems, or none.
    protocol CappedSpecimenCycleRule {
        func check(_ item: CappedSpecimenCycle) -> [String]
    }

    final class CappedSpecimenCycleCreatedAtRangeRule: CappedSpecimenCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedSpecimenCycle) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedSpecimenCycleLimitRangeRule: CappedSpecimenCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedSpecimenCycle) -> [String] {
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

    final class CappedSpecimenCycleSegmentLengthRule: CappedSpecimenCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSpecimenCycle) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSpecimenCycleCopayRangeRule: CappedSpecimenCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedSpecimenCycle) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped specimen cycle.
    final class CappedSpecimenCycleValidator {
        var rules: [any CappedSpecimenCycleRule]

        init(rules: [any CappedSpecimenCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedSpecimenCycle) -> [String] {
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

        func requireValid(_ item: CappedSpecimenCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedSpecimenCycle]) -> [String: [String]] {
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

    static func defaultCappedSpecimenCycleValidator() -> CappedSpecimenCycleValidator {
        return CappedSpecimenCycleValidator(
            rules: [
                CappedSpecimenCycleCreatedAtRangeRule(min: 32, max: 3600),
                CappedSpecimenCycleLimitRangeRule(min: 32, max: 255),
                CappedSpecimenCycleSegmentLengthRule(maxLength: 255),
                CappedSpecimenCycleCopayRangeRule(min: 6.4, max: 4516.4),
            ]
        )
    }
}
