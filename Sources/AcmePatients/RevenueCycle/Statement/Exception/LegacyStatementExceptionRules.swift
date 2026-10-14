import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy statement exception must pass. Check returns its problems, or none.
    protocol LegacyStatementExceptionRule {
        func check(_ item: LegacyStatementException) -> [String]
    }

    final class LegacyStatementExceptionRequiredBedRule: LegacyStatementExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyStatementException) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyStatementExceptionCodeLengthRule: LegacyStatementExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyStatementException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyStatementExceptionBedLengthRule: LegacyStatementExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyStatementException) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyStatementExceptionTitleLengthRule: LegacyStatementExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyStatementException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyStatementExceptionRequiredCodeRule: LegacyStatementExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyStatementException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy statement exception.
    final class LegacyStatementExceptionValidator {
        var rules: [any LegacyStatementExceptionRule]

        init(rules: [any LegacyStatementExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyStatementException) -> [String] {
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

        func requireValid(_ item: LegacyStatementException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyStatementException]) -> [String: [String]] {
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

    static func defaultLegacyStatementExceptionValidator() -> LegacyStatementExceptionValidator {
        return LegacyStatementExceptionValidator(
            rules: [
                LegacyStatementExceptionRequiredBedRule(message: "legacy statement exception needs this field"),
                LegacyStatementExceptionCodeLengthRule(maxLength: 1000),
                LegacyStatementExceptionBedLengthRule(maxLength: 16),
                LegacyStatementExceptionTitleLengthRule(maxLength: 16),
                LegacyStatementExceptionRequiredCodeRule(message: "legacy statement exception needs this field"),
            ]
        )
    }
}
