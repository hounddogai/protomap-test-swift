import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal digest must pass. Check returns its problems, or none.
    protocol GoalDigestRule {
        func check(_ item: GoalDigest) -> [String]
    }

    final class GoalDigestChannelLengthRule: GoalDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalDigest) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalDigestCapacityRangeRule: GoalDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalDigest) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GoalDigestRegionLengthRule: GoalDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalDigest) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalDigestRequiredRegionRule: GoalDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalDigest) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalDigestRequiredNameRule: GoalDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalDigestCodePrefixRule: GoalDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal digest.
    final class GoalDigestValidator {
        var rules: [any GoalDigestRule]

        init(rules: [any GoalDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalDigest]) -> [String: [String]] {
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

    static func defaultGoalDigestValidator() -> GoalDigestValidator {
        return GoalDigestValidator(
            rules: [
                GoalDigestChannelLengthRule(maxLength: 86400),
                GoalDigestCapacityRangeRule(min: 120, max: 255),
                GoalDigestRegionLengthRule(maxLength: 16),
                GoalDigestRequiredRegionRule(message: "goal digest needs an entry"),
                GoalDigestRequiredNameRule(message: "goal digest needs a value"),
                GoalDigestCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
