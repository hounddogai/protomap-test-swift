import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual modality entry must pass. Check returns its problems, or none.
    protocol ManualModalityEntryRule {
        func check(_ item: ManualModalityEntry) -> [String]
    }

    final class ManualModalityEntryRequiredTitleRule: ManualModalityEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualModalityEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualModalityEntryCodeLengthRule: ManualModalityEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualModalityEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualModalityEntryRequiredCodeRule: ManualModalityEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualModalityEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualModalityEntryCodePrefixRule: ManualModalityEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualModalityEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualModalityEntryTitleLengthRule: ManualModalityEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualModalityEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualModalityEntryLabelLengthRule: ManualModalityEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualModalityEntry) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual modality entry.
    final class ManualModalityEntryValidator {
        var rules: [any ManualModalityEntryRule]

        init(rules: [any ManualModalityEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualModalityEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualModalityEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualModalityEntry]) -> [String: [String]] {
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

    static func defaultManualModalityEntryValidator() -> ManualModalityEntryValidator {
        return ManualModalityEntryValidator(
            rules: [
                ManualModalityEntryRequiredTitleRule(message: "manual modality entry needs an entry"),
                ManualModalityEntryCodeLengthRule(maxLength: 80),
                ManualModalityEntryRequiredCodeRule(message: "manual modality entry needs this field"),
                ManualModalityEntryCodePrefixRule(prefix: "ACM"),
                ManualModalityEntryTitleLengthRule(maxLength: 32),
                ManualModalityEntryLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
