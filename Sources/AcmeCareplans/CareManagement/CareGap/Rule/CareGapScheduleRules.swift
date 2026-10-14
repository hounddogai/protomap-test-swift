import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap schedule must pass. Check returns its problems, or none.
    protocol CareGapScheduleRule {
        func check(_ item: CareGapSchedule) -> [String]
    }

    final class CareGapScheduleRegionLengthRule: CareGapScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapSchedule) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapScheduleFloorValueRangeRule: CareGapScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapSchedule) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareGapScheduleFacilityLengthRule: CareGapScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapSchedule) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap schedule.
    final class CareGapScheduleValidator {
        var rules: [any CareGapScheduleRule]

        init(rules: [any CareGapScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapSchedule]) -> [String: [String]] {
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

    static func defaultCareGapScheduleValidator() -> CareGapScheduleValidator {
        return CareGapScheduleValidator(
            rules: [
                CareGapScheduleRegionLengthRule(maxLength: 16),
                CareGapScheduleFloorValueRangeRule(min: 7.4, max: 3771.9),
                CareGapScheduleFacilityLengthRule(maxLength: 16),
            ]
        )
    }
}
