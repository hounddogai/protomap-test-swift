import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure checkpoint must pass. Check returns its problems, or none.
    protocol DisclosureCheckpointRule {
        func check(_ item: DisclosureCheckpoint) -> [String]
    }

    final class DisclosureCheckpointRequiredTitleRule: DisclosureCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureCheckpointRequiredCategoryRule: DisclosureCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureCheckpoint) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureCheckpointCategoryLengthRule: DisclosureCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureCheckpoint) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureCheckpointCodePrefixRule: DisclosureCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure checkpoint.
    final class DisclosureCheckpointValidator {
        var rules: [any DisclosureCheckpointRule]

        init(rules: [any DisclosureCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureCheckpoint) -> [String] {
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

        func requireValid(_ item: DisclosureCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureCheckpoint]) -> [String: [String]] {
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

    static func defaultDisclosureCheckpointValidator() -> DisclosureCheckpointValidator {
        return DisclosureCheckpointValidator(
            rules: [
                DisclosureCheckpointRequiredTitleRule(message: "disclosure checkpoint needs a value"),
                DisclosureCheckpointRequiredCategoryRule(message: "disclosure checkpoint needs an entry"),
                DisclosureCheckpointCategoryLengthRule(maxLength: 3600),
                DisclosureCheckpointCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
