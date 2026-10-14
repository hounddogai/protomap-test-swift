import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up estimate must pass. Check returns its problems, or none.
    protocol FollowUpEstimateRule {
        func check(_ item: FollowUpEstimate) -> [String]
    }

    final class FollowUpEstimateUpdatedAtRangeRule: FollowUpEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpEstimate) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpEstimateCodePrefixRule: FollowUpEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpEstimateVisibleGuardRule: FollowUpEstimateRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FollowUpEstimate) -> [String] {
            if item.visible && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class FollowUpEstimateRequiredOwnerIDRule: FollowUpEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpEstimate) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a follow up estimate.
    final class FollowUpEstimateValidator {
        var rules: [any FollowUpEstimateRule]

        init(rules: [any FollowUpEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpEstimate) -> [String] {
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

        func requireValid(_ item: FollowUpEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpEstimate]) -> [String: [String]] {
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

    static func defaultFollowUpEstimateValidator() -> FollowUpEstimateValidator {
        return FollowUpEstimateValidator(
            rules: [
                FollowUpEstimateUpdatedAtRangeRule(min: 16, max: 1000),
                FollowUpEstimateCodePrefixRule(prefix: "OPS"),
                FollowUpEstimateVisibleGuardRule(limit: 5.7),
                FollowUpEstimateRequiredOwnerIDRule(message: "follow up estimate needs a value"),
            ]
        )
    }
}
