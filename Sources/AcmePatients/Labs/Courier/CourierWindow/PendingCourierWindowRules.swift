import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending courier window must pass. Check returns its problems, or none.
    protocol PendingCourierWindowRule {
        func check(_ item: PendingCourierWindow) -> [String]
    }

    final class PendingCourierWindowRetriesRangeRule: PendingCourierWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCourierWindow) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingCourierWindowCodePrefixRule: PendingCourierWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingCourierWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingCourierWindowCodeLengthRule: PendingCourierWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCourierWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCourierWindowRequiredNameRule: PendingCourierWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCourierWindow) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCourierWindowRequiredLocaleRule: PendingCourierWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCourierWindow) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCourierWindowUnitLengthRule: PendingCourierWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCourierWindow) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending courier window.
    final class PendingCourierWindowValidator {
        var rules: [any PendingCourierWindowRule]

        init(rules: [any PendingCourierWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCourierWindow) -> [String] {
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

        func requireValid(_ item: PendingCourierWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCourierWindow]) -> [String: [String]] {
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

    static func defaultPendingCourierWindowValidator() -> PendingCourierWindowValidator {
        return PendingCourierWindowValidator(
            rules: [
                PendingCourierWindowRetriesRangeRule(min: 32, max: 80),
                PendingCourierWindowCodePrefixRule(prefix: "Q"),
                PendingCourierWindowCodeLengthRule(maxLength: 16),
                PendingCourierWindowRequiredNameRule(message: "pending courier window needs this field"),
                PendingCourierWindowRequiredLocaleRule(message: "pending courier window needs this field"),
                PendingCourierWindowUnitLengthRule(maxLength: 16),
            ]
        )
    }
}
