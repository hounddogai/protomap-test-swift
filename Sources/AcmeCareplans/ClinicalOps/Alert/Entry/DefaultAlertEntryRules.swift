import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a default alert entry must pass. Check returns its problems, or none.
    protocol DefaultAlertEntryRule {
        func check(_ item: DefaultAlertEntry) -> [String]
    }

    final class DefaultAlertEntryTitleLengthRule: DefaultAlertEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultAlertEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultAlertEntryRequiredCodeRule: DefaultAlertEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAlertEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAlertEntryRequiredFacilityRule: DefaultAlertEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAlertEntry) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAlertEntryFacilityLengthRule: DefaultAlertEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultAlertEntry) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default alert entry.
    final class DefaultAlertEntryValidator {
        var rules: [any DefaultAlertEntryRule]

        init(rules: [any DefaultAlertEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultAlertEntry) -> [String] {
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

        func requireValid(_ item: DefaultAlertEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultAlertEntry]) -> [String: [String]] {
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

    static func defaultDefaultAlertEntryValidator() -> DefaultAlertEntryValidator {
        return DefaultAlertEntryValidator(
            rules: [
                DefaultAlertEntryTitleLengthRule(maxLength: 120),
                DefaultAlertEntryRequiredCodeRule(message: "default alert entry needs this field"),
                DefaultAlertEntryRequiredFacilityRule(message: "default alert entry needs this field"),
                DefaultAlertEntryFacilityLengthRule(maxLength: 120),
            ]
        )
    }
}
