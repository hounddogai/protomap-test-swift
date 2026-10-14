import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped network schedule must pass. Check returns its problems, or none.
    protocol CappedNetworkScheduleRule {
        func check(_ item: CappedNetworkSchedule) -> [String]
    }

    final class CappedNetworkScheduleCountryLengthRule: CappedNetworkScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedNetworkSchedule) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedNetworkScheduleScoreRangeRule: CappedNetworkScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedNetworkSchedule) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedNetworkScheduleArchivedGuardRule: CappedNetworkScheduleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CappedNetworkSchedule) -> [String] {
            if item.archived && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a capped network schedule.
    final class CappedNetworkScheduleValidator {
        var rules: [any CappedNetworkScheduleRule]

        init(rules: [any CappedNetworkScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedNetworkSchedule) -> [String] {
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

        func requireValid(_ item: CappedNetworkSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedNetworkSchedule]) -> [String: [String]] {
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

    static func defaultCappedNetworkScheduleValidator() -> CappedNetworkScheduleValidator {
        return CappedNetworkScheduleValidator(
            rules: [
                CappedNetworkScheduleCountryLengthRule(maxLength: 32),
                CappedNetworkScheduleScoreRangeRule(min: 5.7, max: 1956.6),
                CappedNetworkScheduleArchivedGuardRule(limit: 3.5),
            ]
        )
    }
}
