import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled proxy notice must pass. Check returns its problems, or none.
    protocol ScheduledProxyNoticeRule {
        func check(_ item: ScheduledProxyNotice) -> [String]
    }

    final class ScheduledProxyNoticeRequiredTitleRule: ScheduledProxyNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledProxyNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledProxyNoticeAllowedTitleRule: ScheduledProxyNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledProxyNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is unknown"]
            }
            return []
        }
    }

    final class ScheduledProxyNoticeExternalRefLengthRule: ScheduledProxyNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledProxyNotice) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled proxy notice.
    final class ScheduledProxyNoticeValidator {
        var rules: [any ScheduledProxyNoticeRule]

        init(rules: [any ScheduledProxyNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledProxyNotice) -> [String] {
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

        func requireValid(_ item: ScheduledProxyNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledProxyNotice]) -> [String: [String]] {
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

    static func defaultScheduledProxyNoticeValidator() -> ScheduledProxyNoticeValidator {
        return ScheduledProxyNoticeValidator(
            rules: [
                ScheduledProxyNoticeRequiredTitleRule(message: "scheduled proxy notice needs this field"),
                ScheduledProxyNoticeAllowedTitleRule(allowed: ["adaptive", "scheduled"]),
                ScheduledProxyNoticeExternalRefLengthRule(maxLength: 1000),
            ]
        )
    }
}
