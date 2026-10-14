import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance notice must pass. Check returns its problems, or none.
    protocol RemittanceNoticeRule {
        func check(_ item: RemittanceNotice) -> [String]
    }

    final class RemittanceNoticeTitleLengthRule: RemittanceNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceNotice) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceNoticeNotesLengthRule: RemittanceNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceNotice) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceNoticeRequiredNotesRule: RemittanceNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceNotice) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceNoticeRequiredReviewerRule: RemittanceNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceNotice) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceNoticeActiveGuardRule: RemittanceNoticeRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RemittanceNotice) -> [String] {
            if item.active && (item.endsAt > limit) {
                return ["ends at \(item.endsAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance notice.
    final class RemittanceNoticeValidator {
        var rules: [any RemittanceNoticeRule]

        init(rules: [any RemittanceNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceNotice]) -> [String: [String]] {
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

    static func defaultRemittanceNoticeValidator() -> RemittanceNoticeValidator {
        return RemittanceNoticeValidator(
            rules: [
                RemittanceNoticeTitleLengthRule(maxLength: 64),
                RemittanceNoticeNotesLengthRule(maxLength: 64),
                RemittanceNoticeRequiredNotesRule(message: "remittance notice needs an entry"),
                RemittanceNoticeRequiredReviewerRule(message: "remittance notice needs a value"),
                RemittanceNoticeActiveGuardRule(limit: 120),
            ]
        )
    }
}
