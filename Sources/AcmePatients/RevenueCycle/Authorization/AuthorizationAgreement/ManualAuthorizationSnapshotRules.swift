import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual authorization snapshot must pass. Check returns its problems, or none.
    protocol ManualAuthorizationSnapshotRule {
        func check(_ item: ManualAuthorizationSnapshot) -> [String]
    }

    final class ManualAuthorizationSnapshotRequiredTitleRule: ManualAuthorizationSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAuthorizationSnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualAuthorizationSnapshotTitleLengthRule: ManualAuthorizationSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualAuthorizationSnapshot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualAuthorizationSnapshotRequiredCodeRule: ManualAuthorizationSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAuthorizationSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualAuthorizationSnapshotStartsAtRangeRule: ManualAuthorizationSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualAuthorizationSnapshot) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualAuthorizationSnapshotWindowRule: ManualAuthorizationSnapshotRule {
        var maxSpan: Int

        init(maxSpan: Int) {
            self.maxSpan = maxSpan
        }

        func check(_ item: ManualAuthorizationSnapshot) -> [String] {
            if item.startsAt > item.endsAt {
                return ["starts at is after ends at"]
            }
            if maxSpan > 0 && (item.endsAt - item.startsAt > maxSpan) {
                return ["spans more than \(maxSpan) seconds"]
            }
            return []
        }
    }

    final class ManualAuthorizationSnapshotExpiresAtRangeRule: ManualAuthorizationSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualAuthorizationSnapshot) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual authorization snapshot.
    final class ManualAuthorizationSnapshotValidator {
        var rules: [any ManualAuthorizationSnapshotRule]

        init(rules: [any ManualAuthorizationSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualAuthorizationSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualAuthorizationSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualAuthorizationSnapshot]) -> [String: [String]] {
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

    static func defaultManualAuthorizationSnapshotValidator() -> ManualAuthorizationSnapshotValidator {
        return ManualAuthorizationSnapshotValidator(
            rules: [
                ManualAuthorizationSnapshotRequiredTitleRule(message: "manual authorization snapshot needs an entry"),
                ManualAuthorizationSnapshotTitleLengthRule(maxLength: 32),
                ManualAuthorizationSnapshotRequiredCodeRule(message: "manual authorization snapshot needs this field"),
                ManualAuthorizationSnapshotStartsAtRangeRule(min: 16, max: 3600),
                ManualAuthorizationSnapshotWindowRule(maxSpan: 120),
                ManualAuthorizationSnapshotExpiresAtRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
