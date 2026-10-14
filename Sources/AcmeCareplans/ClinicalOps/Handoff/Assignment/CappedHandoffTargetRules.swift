import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a capped handoff target must pass. Check returns its problems, or none.
    protocol CappedHandoffTargetRule {
        func check(_ item: CappedHandoffTarget) -> [String]
    }

    final class CappedHandoffTargetActiveGuardRule: CappedHandoffTargetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CappedHandoffTarget) -> [String] {
            if item.active && (item.windowDays > limit) {
                return ["window days \(item.windowDays) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class CappedHandoffTargetRequiredChannelRule: CappedHandoffTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedHandoffTarget) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedHandoffTargetWindowDaysRangeRule: CappedHandoffTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedHandoffTarget) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedHandoffTargetAllowedCodeRule: CappedHandoffTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedHandoffTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class CappedHandoffTargetBudgetRangeRule: CappedHandoffTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedHandoffTarget) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedHandoffTargetRequiredNameRule: CappedHandoffTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedHandoffTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped handoff target.
    final class CappedHandoffTargetValidator {
        var rules: [any CappedHandoffTargetRule]

        init(rules: [any CappedHandoffTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedHandoffTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedHandoffTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedHandoffTarget]) -> [String: [String]] {
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

    static func defaultCappedHandoffTargetValidator() -> CappedHandoffTargetValidator {
        return CappedHandoffTargetValidator(
            rules: [
                CappedHandoffTargetActiveGuardRule(limit: 1000),
                CappedHandoffTargetRequiredChannelRule(message: "capped handoff target needs a value"),
                CappedHandoffTargetWindowDaysRangeRule(min: 120, max: 1000),
                CappedHandoffTargetAllowedCodeRule(allowed: ["strict", "scheduled", "scheduled"]),
                CappedHandoffTargetBudgetRangeRule(min: 0.7, max: 3426.4),
                CappedHandoffTargetRequiredNameRule(message: "capped handoff target needs a value"),
            ]
        )
    }
}
