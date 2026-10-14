import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning profile must pass. Check returns its problems, or none.
    protocol CleaningProfileRule {
        func check(_ item: CleaningProfile) -> [String]
    }

    final class CleaningProfilePinnedGuardRule: CleaningProfileRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CleaningProfile) -> [String] {
            if item.pinned && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class CleaningProfileVersionRangeRule: CleaningProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningProfile) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CleaningProfileGraceDaysRangeRule: CleaningProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningProfile) -> [String] {
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

    /// Runs every rule of a cleaning profile.
    final class CleaningProfileValidator {
        var rules: [any CleaningProfileRule]

        init(rules: [any CleaningProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningProfile) -> [String] {
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

        func requireValid(_ item: CleaningProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningProfile]) -> [String: [String]] {
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

    static func defaultCleaningProfileValidator() -> CleaningProfileValidator {
        return CleaningProfileValidator(
            rules: [
                CleaningProfilePinnedGuardRule(limit: 120),
                CleaningProfileVersionRangeRule(min: 120, max: 3600),
                CleaningProfileGraceDaysRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
