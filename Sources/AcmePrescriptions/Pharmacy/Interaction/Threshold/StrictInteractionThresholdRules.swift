import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a strict interaction threshold must pass. Check returns its problems, or none.
    protocol StrictInteractionThresholdRule {
        func check(_ item: StrictInteractionThreshold) -> [String]
    }

    final class StrictInteractionThresholdRequiredBedRule: StrictInteractionThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictInteractionThreshold) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictInteractionThresholdMarginRangeRule: StrictInteractionThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictInteractionThreshold) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictInteractionThresholdRequiredReviewerRule: StrictInteractionThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictInteractionThreshold) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictInteractionThresholdWeightRangeRule: StrictInteractionThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictInteractionThreshold) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictInteractionThresholdPinnedGuardRule: StrictInteractionThresholdRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictInteractionThreshold) -> [String] {
            if item.pinned && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class StrictInteractionThresholdCodePrefixRule: StrictInteractionThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictInteractionThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict interaction threshold.
    final class StrictInteractionThresholdValidator {
        var rules: [any StrictInteractionThresholdRule]

        init(rules: [any StrictInteractionThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictInteractionThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictInteractionThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictInteractionThreshold]) -> [String: [String]] {
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

    static func defaultStrictInteractionThresholdValidator() -> StrictInteractionThresholdValidator {
        return StrictInteractionThresholdValidator(
            rules: [
                StrictInteractionThresholdRequiredBedRule(message: "strict interaction threshold needs this field"),
                StrictInteractionThresholdMarginRangeRule(min: 0.0, max: 4671.1),
                StrictInteractionThresholdRequiredReviewerRule(message: "strict interaction threshold needs a value"),
                StrictInteractionThresholdWeightRangeRule(min: 2.8, max: 4841.1),
                StrictInteractionThresholdPinnedGuardRule(limit: 3600),
                StrictInteractionThresholdCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
