import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure snapshot must pass. Check returns its problems, or none.
    protocol ClosureSnapshotRule {
        func check(_ item: ClosureSnapshot) -> [String]
    }

    final class ClosureSnapshotUnitLengthRule: ClosureSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureSnapshot) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureSnapshotAllowedTitleRule: ClosureSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClosureSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is unknown"]
            }
            return []
        }
    }

    final class ClosureSnapshotCodePrefixRule: ClosureSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClosureSnapshotRequiredLocaleRule: ClosureSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureSnapshot) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a closure snapshot.
    final class ClosureSnapshotValidator {
        var rules: [any ClosureSnapshotRule]

        init(rules: [any ClosureSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureSnapshot]) -> [String: [String]] {
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

    static func defaultClosureSnapshotValidator() -> ClosureSnapshotValidator {
        return ClosureSnapshotValidator(
            rules: [
                ClosureSnapshotUnitLengthRule(maxLength: 1000),
                ClosureSnapshotAllowedTitleRule(allowed: ["fallback", "global"]),
                ClosureSnapshotCodePrefixRule(prefix: "Q"),
                ClosureSnapshotRequiredLocaleRule(message: "closure snapshot needs an entry"),
            ]
        )
    }
}
