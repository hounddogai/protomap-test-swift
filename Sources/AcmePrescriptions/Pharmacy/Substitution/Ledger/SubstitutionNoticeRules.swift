import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution notice must pass. Check returns its problems, or none.
    protocol SubstitutionNoticeRule {
        func check(_ item: SubstitutionNotice) -> [String]
    }

    final class SubstitutionNoticeTitleLengthRule: SubstitutionNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionNotice) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionNoticeAllowedTitleRule: SubstitutionNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SubstitutionNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is too long"]
            }
            return []
        }
    }

    final class SubstitutionNoticeLabelLengthRule: SubstitutionNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionNotice) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionNoticeCodeLengthRule: SubstitutionNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution notice.
    final class SubstitutionNoticeValidator {
        var rules: [any SubstitutionNoticeRule]

        init(rules: [any SubstitutionNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionNotice]) -> [String: [String]] {
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

    static func defaultSubstitutionNoticeValidator() -> SubstitutionNoticeValidator {
        return SubstitutionNoticeValidator(
            rules: [
                SubstitutionNoticeTitleLengthRule(maxLength: 32),
                SubstitutionNoticeAllowedTitleRule(allowed: ["scheduled", "global", "adaptive"]),
                SubstitutionNoticeLabelLengthRule(maxLength: 80),
                SubstitutionNoticeCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
