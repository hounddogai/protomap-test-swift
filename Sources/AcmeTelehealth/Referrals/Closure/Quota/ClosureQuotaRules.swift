import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure quota must pass. Check returns its problems, or none.
    protocol ClosureQuotaRule {
        func check(_ item: ClosureQuota) -> [String]
    }

    final class ClosureQuotaActiveGuardRule: ClosureQuotaRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ClosureQuota) -> [String] {
            if item.active && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ClosureQuotaRequiredSegmentRule: ClosureQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureQuota) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureQuotaRequiredTitleRule: ClosureQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureQuotaCostRangeRule: ClosureQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureQuota) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClosureQuotaCodeLengthRule: ClosureQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure quota.
    final class ClosureQuotaValidator {
        var rules: [any ClosureQuotaRule]

        init(rules: [any ClosureQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureQuota) -> [String] {
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

        func requireValid(_ item: ClosureQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureQuota]) -> [String: [String]] {
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

    static func defaultClosureQuotaValidator() -> ClosureQuotaValidator {
        return ClosureQuotaValidator(
            rules: [
                ClosureQuotaActiveGuardRule(limit: 3.6),
                ClosureQuotaRequiredSegmentRule(message: "closure quota needs an entry"),
                ClosureQuotaRequiredTitleRule(message: "closure quota needs an entry"),
                ClosureQuotaCostRangeRule(min: 0.5, max: 600.7),
                ClosureQuotaCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
