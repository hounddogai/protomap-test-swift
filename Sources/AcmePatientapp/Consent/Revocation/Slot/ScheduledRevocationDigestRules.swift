import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled revocation digest must pass. Check returns its problems, or none.
    protocol ScheduledRevocationDigestRule {
        func check(_ item: ScheduledRevocationDigest) -> [String]
    }

    final class ScheduledRevocationDigestStartsAtRangeRule: ScheduledRevocationDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRevocationDigest) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledRevocationDigestUnitLengthRule: ScheduledRevocationDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledRevocationDigest) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledRevocationDigestAllowedNameRule: ScheduledRevocationDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledRevocationDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class ScheduledRevocationDigestRequiredUnitRule: ScheduledRevocationDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRevocationDigest) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled revocation digest.
    final class ScheduledRevocationDigestValidator {
        var rules: [any ScheduledRevocationDigestRule]

        init(rules: [any ScheduledRevocationDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledRevocationDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledRevocationDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledRevocationDigest]) -> [String: [String]] {
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

    static func defaultScheduledRevocationDigestValidator() -> ScheduledRevocationDigestValidator {
        return ScheduledRevocationDigestValidator(
            rules: [
                ScheduledRevocationDigestStartsAtRangeRule(min: 16, max: 1000),
                ScheduledRevocationDigestUnitLengthRule(maxLength: 255),
                ScheduledRevocationDigestAllowedNameRule(allowed: ["scheduled", "scheduled", "scheduled"]),
                ScheduledRevocationDigestRequiredUnitRule(message: "scheduled revocation digest needs an entry"),
            ]
        )
    }
}
