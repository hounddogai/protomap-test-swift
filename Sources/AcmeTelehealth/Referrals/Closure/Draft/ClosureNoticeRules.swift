import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure notice must pass. Check returns its problems, or none.
    protocol ClosureNoticeRule {
        func check(_ item: ClosureNotice) -> [String]
    }

    final class ClosureNoticeActiveGuardRule: ClosureNoticeRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ClosureNotice) -> [String] {
            if item.active && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ClosureNoticeBedLengthRule: ClosureNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureNotice) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureNoticeRequiredBedRule: ClosureNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureNotice) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureNoticeNameLengthRule: ClosureNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureNotice) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureNoticeCodeLengthRule: ClosureNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureNoticeRequiredNameRule: ClosureNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureNotice) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a closure notice.
    final class ClosureNoticeValidator {
        var rules: [any ClosureNoticeRule]

        init(rules: [any ClosureNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureNotice) -> [String] {
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

        func requireValid(_ item: ClosureNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureNotice]) -> [String: [String]] {
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

    static func defaultClosureNoticeValidator() -> ClosureNoticeValidator {
        return ClosureNoticeValidator(
            rules: [
                ClosureNoticeActiveGuardRule(limit: 16),
                ClosureNoticeBedLengthRule(maxLength: 80),
                ClosureNoticeRequiredBedRule(message: "closure notice needs this field"),
                ClosureNoticeNameLengthRule(maxLength: 64),
                ClosureNoticeCodeLengthRule(maxLength: 32),
                ClosureNoticeRequiredNameRule(message: "closure notice needs a value"),
            ]
        )
    }
}
