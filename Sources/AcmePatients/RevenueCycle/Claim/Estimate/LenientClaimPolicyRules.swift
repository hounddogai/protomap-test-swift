import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient claim policy must pass. Check returns its problems, or none.
    protocol LenientClaimPolicyRule {
        func check(_ item: LenientClaimPolicy) -> [String]
    }

    final class LenientClaimPolicyScoreRangeRule: LenientClaimPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientClaimPolicy) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientClaimPolicyArchivedGuardRule: LenientClaimPolicyRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LenientClaimPolicy) -> [String] {
            if item.archived && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class LenientClaimPolicyCodeLengthRule: LenientClaimPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientClaimPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientClaimPolicyRequiredNameRule: LenientClaimPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientClaimPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient claim policy.
    final class LenientClaimPolicyValidator {
        var rules: [any LenientClaimPolicyRule]

        init(rules: [any LenientClaimPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientClaimPolicy) -> [String] {
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

        func requireValid(_ item: LenientClaimPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientClaimPolicy]) -> [String: [String]] {
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

    static func defaultLenientClaimPolicyValidator() -> LenientClaimPolicyValidator {
        return LenientClaimPolicyValidator(
            rules: [
                LenientClaimPolicyScoreRangeRule(min: 3.6, max: 485.7),
                LenientClaimPolicyArchivedGuardRule(limit: 6.4),
                LenientClaimPolicyCodeLengthRule(maxLength: 64),
                LenientClaimPolicyRequiredNameRule(message: "lenient claim policy needs a value"),
            ]
        )
    }
}
