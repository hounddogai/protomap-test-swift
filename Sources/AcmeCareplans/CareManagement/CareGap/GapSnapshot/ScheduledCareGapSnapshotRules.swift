import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled care gap snapshot must pass. Check returns its problems, or none.
    protocol ScheduledCareGapSnapshotRule {
        func check(_ item: ScheduledCareGapSnapshot) -> [String]
    }

    final class ScheduledCareGapSnapshotRequiredCodeRule: ScheduledCareGapSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareGapSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCareGapSnapshotCodeLengthRule: ScheduledCareGapSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareGapSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareGapSnapshotTitleLengthRule: ScheduledCareGapSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareGapSnapshot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareGapSnapshotRequiredTitleRule: ScheduledCareGapSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareGapSnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled care gap snapshot.
    final class ScheduledCareGapSnapshotValidator {
        var rules: [any ScheduledCareGapSnapshotRule]

        init(rules: [any ScheduledCareGapSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCareGapSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCareGapSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCareGapSnapshot]) -> [String: [String]] {
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

    static func defaultScheduledCareGapSnapshotValidator() -> ScheduledCareGapSnapshotValidator {
        return ScheduledCareGapSnapshotValidator(
            rules: [
                ScheduledCareGapSnapshotRequiredCodeRule(message: "scheduled care gap snapshot needs this field"),
                ScheduledCareGapSnapshotCodeLengthRule(maxLength: 255),
                ScheduledCareGapSnapshotTitleLengthRule(maxLength: 32),
                ScheduledCareGapSnapshotRequiredTitleRule(message: "scheduled care gap snapshot needs an entry"),
            ]
        )
    }
}
