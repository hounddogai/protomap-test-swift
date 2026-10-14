import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict statement entry must pass. Check returns its problems, or none.
    protocol StrictStatementEntryRule {
        func check(_ item: StrictStatementEntry) -> [String]
    }

    final class StrictStatementEntryRequiredDescriptionRule: StrictStatementEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictStatementEntry) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictStatementEntryLabelLengthRule: StrictStatementEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictStatementEntry) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictStatementEntryAllowedWardRule: StrictStatementEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictStatementEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is not allowed"]
            }
            return []
        }
    }

    final class StrictStatementEntryWardLengthRule: StrictStatementEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictStatementEntry) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictStatementEntryRequiredLabelRule: StrictStatementEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictStatementEntry) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict statement entry.
    final class StrictStatementEntryValidator {
        var rules: [any StrictStatementEntryRule]

        init(rules: [any StrictStatementEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictStatementEntry) -> [String] {
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

        func requireValid(_ item: StrictStatementEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictStatementEntry]) -> [String: [String]] {
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

    static func defaultStrictStatementEntryValidator() -> StrictStatementEntryValidator {
        return StrictStatementEntryValidator(
            rules: [
                StrictStatementEntryRequiredDescriptionRule(message: "strict statement entry needs an entry"),
                StrictStatementEntryLabelLengthRule(maxLength: 80),
                StrictStatementEntryAllowedWardRule(allowed: []),
                StrictStatementEntryWardLengthRule(maxLength: 16),
                StrictStatementEntryRequiredLabelRule(message: "strict statement entry needs this field"),
            ]
        )
    }
}
