import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier entry must pass. Check returns its problems, or none.
    protocol CourierEntryRule {
        func check(_ item: CourierEntry) -> [String]
    }

    final class CourierEntryRequiredContactEmailRule: CourierEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierEntry) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierEntryCodeLengthRule: CourierEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierEntryAllowedCodeRule: CourierEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a courier entry.
    final class CourierEntryValidator {
        var rules: [any CourierEntryRule]

        init(rules: [any CourierEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierEntry) -> [String] {
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

        func requireValid(_ item: CourierEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierEntry]) -> [String: [String]] {
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

    static func defaultCourierEntryValidator() -> CourierEntryValidator {
        return CourierEntryValidator(
            rules: [
                CourierEntryRequiredContactEmailRule(message: "courier entry needs this field"),
                CourierEntryCodeLengthRule(maxLength: 64),
                CourierEntryAllowedCodeRule(allowed: []),
            ]
        )
    }
}
