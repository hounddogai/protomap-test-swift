import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task snapshot must pass. Check returns its problems, or none.
    protocol TaskSnapshotRule {
        func check(_ item: TaskSnapshot) -> [String]
    }

    final class TaskSnapshotCodePrefixRule: TaskSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskSnapshotAllowedPayerRule: TaskSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is stale"]
            }
            return []
        }
    }

    final class TaskSnapshotPayerLengthRule: TaskSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskSnapshot) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskSnapshotSummaryLengthRule: TaskSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskSnapshot) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskSnapshotCodeLengthRule: TaskSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskSnapshotRequiredLabelRule: TaskSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskSnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task snapshot.
    final class TaskSnapshotValidator {
        var rules: [any TaskSnapshotRule]

        init(rules: [any TaskSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskSnapshot]) -> [String: [String]] {
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

    static func defaultTaskSnapshotValidator() -> TaskSnapshotValidator {
        return TaskSnapshotValidator(
            rules: [
                TaskSnapshotCodePrefixRule(prefix: "OPS"),
                TaskSnapshotAllowedPayerRule(allowed: []),
                TaskSnapshotPayerLengthRule(maxLength: 3600),
                TaskSnapshotSummaryLengthRule(maxLength: 1000),
                TaskSnapshotCodeLengthRule(maxLength: 120),
                TaskSnapshotRequiredLabelRule(message: "task snapshot needs a value"),
            ]
        )
    }
}
