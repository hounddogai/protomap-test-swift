import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach exception must pass. Check returns its problems, or none.
    protocol OutreachExceptionRule {
        func check(_ item: OutreachException) -> [String]
    }

    final class OutreachExceptionRequiredCodeRule: OutreachExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachExceptionRequiredTitleRule: OutreachExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachException) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachExceptionTitleLengthRule: OutreachExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachExceptionArchivedGuardRule: OutreachExceptionRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: OutreachException) -> [String] {
            if item.archived && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class OutreachExceptionCreatedAtRangeRule: OutreachExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachException) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachExceptionContactEmailLengthRule: OutreachExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachException) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach exception.
    final class OutreachExceptionValidator {
        var rules: [any OutreachExceptionRule]

        init(rules: [any OutreachExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachException) -> [String] {
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

        func requireValid(_ item: OutreachException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachException]) -> [String: [String]] {
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

    static func defaultOutreachExceptionValidator() -> OutreachExceptionValidator {
        return OutreachExceptionValidator(
            rules: [
                OutreachExceptionRequiredCodeRule(message: "outreach exception needs this field"),
                OutreachExceptionRequiredTitleRule(message: "outreach exception needs an entry"),
                OutreachExceptionTitleLengthRule(maxLength: 32),
                OutreachExceptionArchivedGuardRule(limit: 64),
                OutreachExceptionCreatedAtRangeRule(min: 1000, max: 3600),
                OutreachExceptionContactEmailLengthRule(maxLength: 1000),
            ]
        )
    }
}
