import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a legacy overtime snapshot must pass. Check returns its problems, or none.
    protocol LegacyOvertimeSnapshotRule {
        func check(_ item: LegacyOvertimeSnapshot) -> [String]
    }

    final class LegacyOvertimeSnapshotRequiredBedRule: LegacyOvertimeSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyOvertimeSnapshot) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyOvertimeSnapshotTitleLengthRule: LegacyOvertimeSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOvertimeSnapshot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyOvertimeSnapshotCodeLengthRule: LegacyOvertimeSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOvertimeSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy overtime snapshot.
    final class LegacyOvertimeSnapshotValidator {
        var rules: [any LegacyOvertimeSnapshotRule]

        init(rules: [any LegacyOvertimeSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyOvertimeSnapshot) -> [String] {
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

        func requireValid(_ item: LegacyOvertimeSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyOvertimeSnapshot]) -> [String: [String]] {
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

    static func defaultLegacyOvertimeSnapshotValidator() -> LegacyOvertimeSnapshotValidator {
        return LegacyOvertimeSnapshotValidator(
            rules: [
                LegacyOvertimeSnapshotRequiredBedRule(message: "legacy overtime snapshot needs this field"),
                LegacyOvertimeSnapshotTitleLengthRule(maxLength: 64),
                LegacyOvertimeSnapshotCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
