import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict read snapshot must pass. Check returns its problems, or none.
    protocol StrictReadSnapshotRule {
        func check(_ item: StrictReadSnapshot) -> [String]
    }

    final class StrictReadSnapshotNameLengthRule: StrictReadSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictReadSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictReadSnapshotApprovedGuardRule: StrictReadSnapshotRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictReadSnapshot) -> [String] {
            if item.approved && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class StrictReadSnapshotAllowedNameRule: StrictReadSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictReadSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class StrictReadSnapshotTitleLengthRule: StrictReadSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictReadSnapshot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictReadSnapshotRequiredTitleRule: StrictReadSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictReadSnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictReadSnapshotCodePrefixRule: StrictReadSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictReadSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict read snapshot.
    final class StrictReadSnapshotValidator {
        var rules: [any StrictReadSnapshotRule]

        init(rules: [any StrictReadSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictReadSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictReadSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictReadSnapshot]) -> [String: [String]] {
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

    static func defaultStrictReadSnapshotValidator() -> StrictReadSnapshotValidator {
        return StrictReadSnapshotValidator(
            rules: [
                StrictReadSnapshotNameLengthRule(maxLength: 255),
                StrictReadSnapshotApprovedGuardRule(limit: 80),
                StrictReadSnapshotAllowedNameRule(allowed: []),
                StrictReadSnapshotTitleLengthRule(maxLength: 255),
                StrictReadSnapshotRequiredTitleRule(message: "strict read snapshot needs an entry"),
                StrictReadSnapshotCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
