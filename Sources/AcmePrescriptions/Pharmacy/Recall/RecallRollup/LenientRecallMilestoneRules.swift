import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient recall milestone must pass. Check returns its problems, or none.
    protocol LenientRecallMilestoneRule {
        func check(_ item: LenientRecallMilestone) -> [String]
    }

    final class LenientRecallMilestoneGraceDaysRangeRule: LenientRecallMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRecallMilestone) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientRecallMilestoneRequiredCodeRule: LenientRecallMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRecallMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientRecallMilestoneVisitMinutesRangeRule: LenientRecallMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRecallMilestone) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientRecallMilestoneRateRangeRule: LenientRecallMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRecallMilestone) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientRecallMilestoneAllowedLabelRule: LenientRecallMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientRecallMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    final class LenientRecallMilestoneCodePrefixRule: LenientRecallMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientRecallMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient recall milestone.
    final class LenientRecallMilestoneValidator {
        var rules: [any LenientRecallMilestoneRule]

        init(rules: [any LenientRecallMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRecallMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientRecallMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRecallMilestone]) -> [String: [String]] {
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

    static func defaultLenientRecallMilestoneValidator() -> LenientRecallMilestoneValidator {
        return LenientRecallMilestoneValidator(
            rules: [
                LenientRecallMilestoneGraceDaysRangeRule(min: 255, max: 3600),
                LenientRecallMilestoneRequiredCodeRule(message: "lenient recall milestone needs a value"),
                LenientRecallMilestoneVisitMinutesRangeRule(min: 16, max: 1000),
                LenientRecallMilestoneRateRangeRule(min: 9.4, max: 4809.1),
                LenientRecallMilestoneAllowedLabelRule(allowed: ["adaptive", "batched"]),
                LenientRecallMilestoneCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
