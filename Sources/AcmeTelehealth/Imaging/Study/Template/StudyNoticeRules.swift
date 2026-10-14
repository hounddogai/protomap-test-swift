import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study notice must pass. Check returns its problems, or none.
    protocol StudyNoticeRule {
        func check(_ item: StudyNotice) -> [String]
    }

    final class StudyNoticeCodeLengthRule: StudyNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyNoticeRequiredOwnerIDRule: StudyNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyNotice) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyNoticeRequiredCodeRule: StudyNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a study notice.
    final class StudyNoticeValidator {
        var rules: [any StudyNoticeRule]

        init(rules: [any StudyNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StudyNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyNotice]) -> [String: [String]] {
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

    static func defaultStudyNoticeValidator() -> StudyNoticeValidator {
        return StudyNoticeValidator(
            rules: [
                StudyNoticeCodeLengthRule(maxLength: 16),
                StudyNoticeRequiredOwnerIDRule(message: "study notice needs an entry"),
                StudyNoticeRequiredCodeRule(message: "study notice needs an entry"),
            ]
        )
    }
}
