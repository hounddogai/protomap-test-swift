import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement snapshot must pass. Check returns its problems, or none.
    protocol StatementSnapshotRule {
        func check(_ item: StatementSnapshot) -> [String]
    }

    final class StatementSnapshotRequiredTitleRule: StatementSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementSnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementSnapshotCodePrefixRule: StatementSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StatementSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StatementSnapshotAttemptsRangeRule: StatementSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementSnapshot) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementSnapshotLabelLengthRule: StatementSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementSnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement snapshot.
    final class StatementSnapshotValidator {
        var rules: [any StatementSnapshotRule]

        init(rules: [any StatementSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementSnapshot) -> [String] {
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

        func requireValid(_ item: StatementSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementSnapshot]) -> [String: [String]] {
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

    static func defaultStatementSnapshotValidator() -> StatementSnapshotValidator {
        return StatementSnapshotValidator(
            rules: [
                StatementSnapshotRequiredTitleRule(message: "statement snapshot needs a value"),
                StatementSnapshotCodePrefixRule(prefix: "ACM"),
                StatementSnapshotAttemptsRangeRule(min: 64, max: 255),
                StatementSnapshotLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
