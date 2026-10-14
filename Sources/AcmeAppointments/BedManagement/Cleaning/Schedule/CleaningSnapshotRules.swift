import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning snapshot must pass. Check returns its problems, or none.
    protocol CleaningSnapshotRule {
        func check(_ item: CleaningSnapshot) -> [String]
    }

    final class CleaningSnapshotAllowedCodeRule: CleaningSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CleaningSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class CleaningSnapshotTitleLengthRule: CleaningSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningSnapshot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningSnapshotRequiredNameRule: CleaningSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningSnapshotRequiredCodeRule: CleaningSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning snapshot.
    final class CleaningSnapshotValidator {
        var rules: [any CleaningSnapshotRule]

        init(rules: [any CleaningSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningSnapshot]) -> [String: [String]] {
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

    static func defaultCleaningSnapshotValidator() -> CleaningSnapshotValidator {
        return CleaningSnapshotValidator(
            rules: [
                CleaningSnapshotAllowedCodeRule(allowed: ["legacy", "regional", "weighted"]),
                CleaningSnapshotTitleLengthRule(maxLength: 86400),
                CleaningSnapshotRequiredNameRule(message: "cleaning snapshot needs a value"),
                CleaningSnapshotRequiredCodeRule(message: "cleaning snapshot needs this field"),
            ]
        )
    }
}
