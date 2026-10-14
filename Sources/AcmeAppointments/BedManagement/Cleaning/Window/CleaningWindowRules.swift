import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning window must pass. Check returns its problems, or none.
    protocol CleaningWindowRule {
        func check(_ item: CleaningWindow) -> [String]
    }

    final class CleaningWindowRequiredCodeRule: CleaningWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningWindowRequiredChecksumRule: CleaningWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningWindow) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningWindowCodeLengthRule: CleaningWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningWindowAllowedCodeRule: CleaningWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CleaningWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning window.
    final class CleaningWindowValidator {
        var rules: [any CleaningWindowRule]

        init(rules: [any CleaningWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningWindow]) -> [String: [String]] {
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

    static func defaultCleaningWindowValidator() -> CleaningWindowValidator {
        return CleaningWindowValidator(
            rules: [
                CleaningWindowRequiredCodeRule(message: "cleaning window needs an entry"),
                CleaningWindowRequiredChecksumRule(message: "cleaning window needs a value"),
                CleaningWindowCodeLengthRule(maxLength: 120),
                CleaningWindowAllowedCodeRule(allowed: ["seasonal", "batched"]),
            ]
        )
    }
}
