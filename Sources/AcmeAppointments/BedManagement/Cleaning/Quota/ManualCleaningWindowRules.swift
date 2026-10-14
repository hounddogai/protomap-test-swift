import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual cleaning window must pass. Check returns its problems, or none.
    protocol ManualCleaningWindowRule {
        func check(_ item: ManualCleaningWindow) -> [String]
    }

    final class ManualCleaningWindowRequiredPhoneRule: ManualCleaningWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCleaningWindow) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCleaningWindowLabelLengthRule: ManualCleaningWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCleaningWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCleaningWindowRequiredCodeRule: ManualCleaningWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCleaningWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCleaningWindowCodeLengthRule: ManualCleaningWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCleaningWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual cleaning window.
    final class ManualCleaningWindowValidator {
        var rules: [any ManualCleaningWindowRule]

        init(rules: [any ManualCleaningWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCleaningWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualCleaningWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCleaningWindow]) -> [String: [String]] {
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

    static func defaultManualCleaningWindowValidator() -> ManualCleaningWindowValidator {
        return ManualCleaningWindowValidator(
            rules: [
                ManualCleaningWindowRequiredPhoneRule(message: "manual cleaning window needs this field"),
                ManualCleaningWindowLabelLengthRule(maxLength: 80),
                ManualCleaningWindowRequiredCodeRule(message: "manual cleaning window needs a value"),
                ManualCleaningWindowCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
