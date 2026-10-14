import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual language snapshot must pass. Check returns its problems, or none.
    protocol ManualLanguageSnapshotRule {
        func check(_ item: ManualLanguageSnapshot) -> [String]
    }

    final class ManualLanguageSnapshotWardLengthRule: ManualLanguageSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualLanguageSnapshot) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualLanguageSnapshotTagsLimitRule: ManualLanguageSnapshotRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ManualLanguageSnapshot) -> [String] {
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

    final class ManualLanguageSnapshotDurationMinutesRangeRule: ManualLanguageSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualLanguageSnapshot) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualLanguageSnapshotRequiredLabelRule: ManualLanguageSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualLanguageSnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualLanguageSnapshotRequiredCurrencyRule: ManualLanguageSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualLanguageSnapshot) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual language snapshot.
    final class ManualLanguageSnapshotValidator {
        var rules: [any ManualLanguageSnapshotRule]

        init(rules: [any ManualLanguageSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualLanguageSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualLanguageSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualLanguageSnapshot]) -> [String: [String]] {
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

    static func defaultManualLanguageSnapshotValidator() -> ManualLanguageSnapshotValidator {
        return ManualLanguageSnapshotValidator(
            rules: [
                ManualLanguageSnapshotWardLengthRule(maxLength: 255),
                ManualLanguageSnapshotTagsLimitRule(maxCount: 16, banned: ["scheduled"]),
                ManualLanguageSnapshotDurationMinutesRangeRule(min: 16, max: 32),
                ManualLanguageSnapshotRequiredLabelRule(message: "manual language snapshot needs a value"),
                ManualLanguageSnapshotRequiredCurrencyRule(message: "manual language snapshot needs an entry"),
            ]
        )
    }
}
