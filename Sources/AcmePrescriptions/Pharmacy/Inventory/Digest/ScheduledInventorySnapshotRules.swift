import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a scheduled inventory snapshot must pass. Check returns its problems, or none.
    protocol ScheduledInventorySnapshotRule {
        func check(_ item: ScheduledInventorySnapshot) -> [String]
    }

    final class ScheduledInventorySnapshotRefillsRangeRule: ScheduledInventorySnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledInventorySnapshot) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledInventorySnapshotCodeLengthRule: ScheduledInventorySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledInventorySnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledInventorySnapshotRequiredTitleRule: ScheduledInventorySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledInventorySnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledInventorySnapshotAllowedCodeRule: ScheduledInventorySnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledInventorySnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class ScheduledInventorySnapshotVisitMinutesRangeRule: ScheduledInventorySnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledInventorySnapshot) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledInventorySnapshotCodePrefixRule: ScheduledInventorySnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledInventorySnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled inventory snapshot.
    final class ScheduledInventorySnapshotValidator {
        var rules: [any ScheduledInventorySnapshotRule]

        init(rules: [any ScheduledInventorySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledInventorySnapshot) -> [String] {
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

        func requireValid(_ item: ScheduledInventorySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledInventorySnapshot]) -> [String: [String]] {
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

    static func defaultScheduledInventorySnapshotValidator() -> ScheduledInventorySnapshotValidator {
        return ScheduledInventorySnapshotValidator(
            rules: [
                ScheduledInventorySnapshotRefillsRangeRule(min: 16, max: 86400),
                ScheduledInventorySnapshotCodeLengthRule(maxLength: 3600),
                ScheduledInventorySnapshotRequiredTitleRule(message: "scheduled inventory snapshot needs an entry"),
                ScheduledInventorySnapshotAllowedCodeRule(allowed: ["adaptive", "default", "strict"]),
                ScheduledInventorySnapshotVisitMinutesRangeRule(min: 80, max: 1000),
                ScheduledInventorySnapshotCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
