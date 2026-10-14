import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual consent form entry must pass. Check returns its problems, or none.
    protocol ManualConsentFormEntryRule {
        func check(_ item: ManualConsentFormEntry) -> [String]
    }

    final class ManualConsentFormEntryNameLengthRule: ManualConsentFormEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualConsentFormEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualConsentFormEntryCodePrefixRule: ManualConsentFormEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualConsentFormEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualConsentFormEntryRequiredNameRule: ManualConsentFormEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualConsentFormEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual consent form entry.
    final class ManualConsentFormEntryValidator {
        var rules: [any ManualConsentFormEntryRule]

        init(rules: [any ManualConsentFormEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualConsentFormEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualConsentFormEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualConsentFormEntry]) -> [String: [String]] {
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

    static func defaultManualConsentFormEntryValidator() -> ManualConsentFormEntryValidator {
        return ManualConsentFormEntryValidator(
            rules: [
                ManualConsentFormEntryNameLengthRule(maxLength: 1000),
                ManualConsentFormEntryCodePrefixRule(prefix: "X"),
                ManualConsentFormEntryRequiredNameRule(message: "manual consent form entry needs this field"),
            ]
        )
    }
}
