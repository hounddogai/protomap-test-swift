import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling cleaning record must pass. Check returns its problems, or none.
    protocol RollingCleaningRecordRule {
        func check(_ item: RollingCleaningRecord) -> [String]
    }

    final class RollingCleaningRecordRequiredWardRule: RollingCleaningRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCleaningRecord) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCleaningRecordMaximumRangeRule: RollingCleaningRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCleaningRecord) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingCleaningRecordScoreRangeRule: RollingCleaningRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCleaningRecord) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingCleaningRecordTagsLimitRule: RollingCleaningRecordRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RollingCleaningRecord) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    /// Runs every rule of a rolling cleaning record.
    final class RollingCleaningRecordValidator {
        var rules: [any RollingCleaningRecordRule]

        init(rules: [any RollingCleaningRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCleaningRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingCleaningRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCleaningRecord]) -> [String: [String]] {
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

    static func defaultRollingCleaningRecordValidator() -> RollingCleaningRecordValidator {
        return RollingCleaningRecordValidator(
            rules: [
                RollingCleaningRecordRequiredWardRule(message: "rolling cleaning record needs an entry"),
                RollingCleaningRecordMaximumRangeRule(min: 9.1, max: 863.6),
                RollingCleaningRecordScoreRangeRule(min: 9.1, max: 216.3),
                RollingCleaningRecordTagsLimitRule(maxCount: 64, banned: ["capped", "rolling", "global"]),
            ]
        )
    }
}
