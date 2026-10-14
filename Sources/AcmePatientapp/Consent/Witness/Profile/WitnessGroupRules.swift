import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness group must pass. Check returns its problems, or none.
    protocol WitnessGroupRule {
        func check(_ item: WitnessGroup) -> [String]
    }

    final class WitnessGroupRequiredCodeRule: WitnessGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessGroupRequiredFacilityRule: WitnessGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessGroup) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessGroupAllowedFacilityRule: WitnessGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is stale"]
            }
            return []
        }
    }

    final class WitnessGroupFacilityLengthRule: WitnessGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessGroup) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessGroupTagsLimitRule: WitnessGroupRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: WitnessGroup) -> [String] {
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

    /// Runs every rule of a witness group.
    final class WitnessGroupValidator {
        var rules: [any WitnessGroupRule]

        init(rules: [any WitnessGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessGroup]) -> [String: [String]] {
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

    static func defaultWitnessGroupValidator() -> WitnessGroupValidator {
        return WitnessGroupValidator(
            rules: [
                WitnessGroupRequiredCodeRule(message: "witness group needs this field"),
                WitnessGroupRequiredFacilityRule(message: "witness group needs this field"),
                WitnessGroupAllowedFacilityRule(allowed: ["tiered", "default", "manual"]),
                WitnessGroupFacilityLengthRule(maxLength: 80),
                WitnessGroupTagsLimitRule(maxCount: 64, banned: ["regional", "adaptive", "adaptive"]),
            ]
        )
    }
}
