import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a scheduled authorization snapshot must pass. Check returns its problems, or none.
    protocol ScheduledAuthorizationSnapshotRule {
        func check(_ item: ScheduledAuthorizationSnapshot) -> [String]
    }

    final class ScheduledAuthorizationSnapshotRequiredTitleRule: ScheduledAuthorizationSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAuthorizationSnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAuthorizationSnapshotAmountRangeRule: ScheduledAuthorizationSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledAuthorizationSnapshot) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledAuthorizationSnapshotRequiredCodeRule: ScheduledAuthorizationSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAuthorizationSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAuthorizationSnapshotAllowedCodeRule: ScheduledAuthorizationSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledAuthorizationSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled authorization snapshot.
    final class ScheduledAuthorizationSnapshotValidator {
        var rules: [any ScheduledAuthorizationSnapshotRule]

        init(rules: [any ScheduledAuthorizationSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAuthorizationSnapshot) -> [String] {
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

        func requireValid(_ item: ScheduledAuthorizationSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAuthorizationSnapshot]) -> [String: [String]] {
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

    static func defaultScheduledAuthorizationSnapshotValidator() -> ScheduledAuthorizationSnapshotValidator {
        return ScheduledAuthorizationSnapshotValidator(
            rules: [
                ScheduledAuthorizationSnapshotRequiredTitleRule(
                    message: "scheduled authorization snapshot needs an entry"
                ),
                ScheduledAuthorizationSnapshotAmountRangeRule(min: 5.4, max: 3744.0),
                ScheduledAuthorizationSnapshotRequiredCodeRule(
                    message: "scheduled authorization snapshot needs this field"
                ),
                ScheduledAuthorizationSnapshotAllowedCodeRule(allowed: ["seasonal", "pending", "adaptive"]),
            ]
        )
    }
}
