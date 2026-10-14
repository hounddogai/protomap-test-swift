import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure snapshot must pass. Check returns its problems, or none.
    protocol DisclosureSnapshotRule {
        func check(_ item: DisclosureSnapshot) -> [String]
    }

    final class DisclosureSnapshotRequiredTimezoneRule: DisclosureSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureSnapshot) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureSnapshotRequiredCodeRule: DisclosureSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureSnapshotRequiredTitleRule: DisclosureSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureSnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure snapshot.
    final class DisclosureSnapshotValidator {
        var rules: [any DisclosureSnapshotRule]

        init(rules: [any DisclosureSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureSnapshot]) -> [String: [String]] {
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

    static func defaultDisclosureSnapshotValidator() -> DisclosureSnapshotValidator {
        return DisclosureSnapshotValidator(
            rules: [
                DisclosureSnapshotRequiredTimezoneRule(message: "disclosure snapshot needs a value"),
                DisclosureSnapshotRequiredCodeRule(message: "disclosure snapshot needs an entry"),
                DisclosureSnapshotRequiredTitleRule(message: "disclosure snapshot needs this field"),
            ]
        )
    }
}
