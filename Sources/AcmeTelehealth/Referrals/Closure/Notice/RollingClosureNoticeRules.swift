import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling closure notice must pass. Check returns its problems, or none.
    protocol RollingClosureNoticeRule {
        func check(_ item: RollingClosureNotice) -> [String]
    }

    final class RollingClosureNoticeCapacityRangeRule: RollingClosureNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingClosureNotice) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingClosureNoticeCreatedAtRangeRule: RollingClosureNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingClosureNotice) -> [String] {
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

    final class RollingClosureNoticeArchivedGuardRule: RollingClosureNoticeRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RollingClosureNotice) -> [String] {
            if item.archived && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class RollingClosureNoticeMinimumRangeRule: RollingClosureNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingClosureNotice) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling closure notice.
    final class RollingClosureNoticeValidator {
        var rules: [any RollingClosureNoticeRule]

        init(rules: [any RollingClosureNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingClosureNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingClosureNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingClosureNotice]) -> [String: [String]] {
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

    static func defaultRollingClosureNoticeValidator() -> RollingClosureNoticeValidator {
        return RollingClosureNoticeValidator(
            rules: [
                RollingClosureNoticeCapacityRangeRule(min: 120, max: 3600),
                RollingClosureNoticeCreatedAtRangeRule(min: 80, max: 80),
                RollingClosureNoticeArchivedGuardRule(limit: 16),
                RollingClosureNoticeMinimumRangeRule(min: 9.3, max: 3927.6),
            ]
        )
    }
}
