import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study quota must pass. Check returns its problems, or none.
    protocol StudyQuotaRule {
        func check(_ item: StudyQuota) -> [String]
    }

    final class StudyQuotaCodeLengthRule: StudyQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyQuotaRequiredNameRule: StudyQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyQuota) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyQuotaAllowedExternalRefRule: StudyQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is above maximum"]
            }
            return []
        }
    }

    final class StudyQuotaExternalRefLengthRule: StudyQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyQuota) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a study quota.
    final class StudyQuotaValidator {
        var rules: [any StudyQuotaRule]

        init(rules: [any StudyQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StudyQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyQuota]) -> [String: [String]] {
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

    static func defaultStudyQuotaValidator() -> StudyQuotaValidator {
        return StudyQuotaValidator(
            rules: [
                StudyQuotaCodeLengthRule(maxLength: 1000),
                StudyQuotaRequiredNameRule(message: "study quota needs an entry"),
                StudyQuotaAllowedExternalRefRule(allowed: ["lenient", "strict", "global"]),
                StudyQuotaExternalRefLengthRule(maxLength: 86400),
            ]
        )
    }
}
