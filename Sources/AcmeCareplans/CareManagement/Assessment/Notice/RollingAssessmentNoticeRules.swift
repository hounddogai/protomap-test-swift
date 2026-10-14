import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling assessment notice must pass. Check returns its problems, or none.
    protocol RollingAssessmentNoticeRule {
        func check(_ item: RollingAssessmentNotice) -> [String]
    }

    final class RollingAssessmentNoticeRequiredWardRule: RollingAssessmentNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAssessmentNotice) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAssessmentNoticeTitleLengthRule: RollingAssessmentNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAssessmentNotice) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAssessmentNoticeAllowedWardRule: RollingAssessmentNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingAssessmentNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is out of range"]
            }
            return []
        }
    }

    final class RollingAssessmentNoticeRequiredTitleRule: RollingAssessmentNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAssessmentNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAssessmentNoticeRequiredCodeRule: RollingAssessmentNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAssessmentNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling assessment notice.
    final class RollingAssessmentNoticeValidator {
        var rules: [any RollingAssessmentNoticeRule]

        init(rules: [any RollingAssessmentNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAssessmentNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingAssessmentNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAssessmentNotice]) -> [String: [String]] {
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

    static func defaultRollingAssessmentNoticeValidator() -> RollingAssessmentNoticeValidator {
        return RollingAssessmentNoticeValidator(
            rules: [
                RollingAssessmentNoticeRequiredWardRule(message: "rolling assessment notice needs this field"),
                RollingAssessmentNoticeTitleLengthRule(maxLength: 1000),
                RollingAssessmentNoticeAllowedWardRule(allowed: ["batched", "weighted", "batched"]),
                RollingAssessmentNoticeRequiredTitleRule(message: "rolling assessment notice needs this field"),
                RollingAssessmentNoticeRequiredCodeRule(message: "rolling assessment notice needs an entry"),
            ]
        )
    }
}
