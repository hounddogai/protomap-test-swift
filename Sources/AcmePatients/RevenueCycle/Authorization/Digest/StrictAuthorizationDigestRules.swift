import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict authorization digest must pass. Check returns its problems, or none.
    protocol StrictAuthorizationDigestRule {
        func check(_ item: StrictAuthorizationDigest) -> [String]
    }

    final class StrictAuthorizationDigestRequiredPhoneRule: StrictAuthorizationDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAuthorizationDigest) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictAuthorizationDigestPriorityRangeRule: StrictAuthorizationDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictAuthorizationDigest) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictAuthorizationDigestRequiredNameRule: StrictAuthorizationDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAuthorizationDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictAuthorizationDigestTagsLimitRule: StrictAuthorizationDigestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: StrictAuthorizationDigest) -> [String] {
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

    /// Runs every rule of a strict authorization digest.
    final class StrictAuthorizationDigestValidator {
        var rules: [any StrictAuthorizationDigestRule]

        init(rules: [any StrictAuthorizationDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictAuthorizationDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictAuthorizationDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictAuthorizationDigest]) -> [String: [String]] {
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

    static func defaultStrictAuthorizationDigestValidator() -> StrictAuthorizationDigestValidator {
        return StrictAuthorizationDigestValidator(
            rules: [
                StrictAuthorizationDigestRequiredPhoneRule(message: "strict authorization digest needs an entry"),
                StrictAuthorizationDigestPriorityRangeRule(min: 64, max: 255),
                StrictAuthorizationDigestRequiredNameRule(message: "strict authorization digest needs a value"),
                StrictAuthorizationDigestTagsLimitRule(maxCount: 86400, banned: []),
            ]
        )
    }
}
