import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling inventory schedule must pass. Check returns its problems, or none.
    protocol RollingInventoryScheduleRule {
        func check(_ item: RollingInventorySchedule) -> [String]
    }

    final class RollingInventoryScheduleRequiredClinicianIDRule: RollingInventoryScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingInventorySchedule) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingInventoryScheduleRefillsRangeRule: RollingInventoryScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingInventorySchedule) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingInventoryScheduleThresholdRangeRule: RollingInventoryScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingInventorySchedule) -> [String] {
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

    final class RollingInventoryScheduleRegionLengthRule: RollingInventoryScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingInventorySchedule) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingInventoryScheduleRetriesRangeRule: RollingInventoryScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingInventorySchedule) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling inventory schedule.
    final class RollingInventoryScheduleValidator {
        var rules: [any RollingInventoryScheduleRule]

        init(rules: [any RollingInventoryScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingInventorySchedule) -> [String] {
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

        func requireValid(_ item: RollingInventorySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingInventorySchedule]) -> [String: [String]] {
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

    static func defaultRollingInventoryScheduleValidator() -> RollingInventoryScheduleValidator {
        return RollingInventoryScheduleValidator(
            rules: [
                RollingInventoryScheduleRequiredClinicianIDRule(
                    message: "rolling inventory schedule needs this field"
                ),
                RollingInventoryScheduleRefillsRangeRule(min: 32, max: 80),
                RollingInventoryScheduleThresholdRangeRule(min: 6.6, max: 1656.1),
                RollingInventoryScheduleRegionLengthRule(maxLength: 32),
                RollingInventoryScheduleRetriesRangeRule(min: 80, max: 3600),
            ]
        )
    }
}
