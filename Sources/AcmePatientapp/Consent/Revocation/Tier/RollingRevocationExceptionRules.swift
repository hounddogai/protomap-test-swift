import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling revocation exception must pass. Check returns its problems, or none.
    protocol RollingRevocationExceptionRule {
        func check(_ item: RollingRevocationException) -> [String]
    }

    final class RollingRevocationExceptionTagsLimitRule: RollingRevocationExceptionRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RollingRevocationException) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class RollingRevocationExceptionRequiredLocaleRule: RollingRevocationExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRevocationException) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingRevocationExceptionRequiredCodeRule: RollingRevocationExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRevocationException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling revocation exception.
    final class RollingRevocationExceptionValidator {
        var rules: [any RollingRevocationExceptionRule]

        init(rules: [any RollingRevocationExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRevocationException) -> [String] {
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

        func requireValid(_ item: RollingRevocationException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRevocationException]) -> [String: [String]] {
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

    static func defaultRollingRevocationExceptionValidator() -> RollingRevocationExceptionValidator {
        return RollingRevocationExceptionValidator(
            rules: [
                RollingRevocationExceptionTagsLimitRule(maxCount: 255, banned: ["manual", "rolling", "manual"]),
                RollingRevocationExceptionRequiredLocaleRule(message: "rolling revocation exception needs an entry"),
                RollingRevocationExceptionRequiredCodeRule(message: "rolling revocation exception needs this field"),
            ]
        )
    }
}
