import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled shift profile must pass. Check returns its problems, or none.
    protocol ScheduledShiftProfileRule {
        func check(_ item: ScheduledShiftProfile) -> [String]
    }

    final class ScheduledShiftProfileArchivedGuardRule: ScheduledShiftProfileRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ScheduledShiftProfile) -> [String] {
            if item.archived && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class ScheduledShiftProfileChecksumLengthRule: ScheduledShiftProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledShiftProfile) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledShiftProfileSequenceRangeRule: ScheduledShiftProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledShiftProfile) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled shift profile.
    final class ScheduledShiftProfileValidator {
        var rules: [any ScheduledShiftProfileRule]

        init(rules: [any ScheduledShiftProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledShiftProfile) -> [String] {
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

        func requireValid(_ item: ScheduledShiftProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledShiftProfile]) -> [String: [String]] {
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

    static func defaultScheduledShiftProfileValidator() -> ScheduledShiftProfileValidator {
        return ScheduledShiftProfileValidator(
            rules: [
                ScheduledShiftProfileArchivedGuardRule(limit: 1000),
                ScheduledShiftProfileChecksumLengthRule(maxLength: 255),
                ScheduledShiftProfileSequenceRangeRule(min: 32, max: 120),
            ]
        )
    }
}
