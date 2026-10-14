import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict courier target must pass. Check returns its problems, or none.
    protocol StrictCourierTargetRule {
        func check(_ item: StrictCourierTarget) -> [String]
    }

    final class StrictCourierTargetCodePrefixRule: StrictCourierTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictCourierTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictCourierTargetVisitMinutesRangeRule: StrictCourierTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictCourierTarget) -> [String] {
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

    final class StrictCourierTargetRequiredCodeRule: StrictCourierTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCourierTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCourierTargetRequiredReviewerRule: StrictCourierTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCourierTarget) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCourierTargetUpdatedAtRangeRule: StrictCourierTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictCourierTarget) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict courier target.
    final class StrictCourierTargetValidator {
        var rules: [any StrictCourierTargetRule]

        init(rules: [any StrictCourierTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictCourierTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictCourierTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictCourierTarget]) -> [String: [String]] {
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

    static func defaultStrictCourierTargetValidator() -> StrictCourierTargetValidator {
        return StrictCourierTargetValidator(
            rules: [
                StrictCourierTargetCodePrefixRule(prefix: "X"),
                StrictCourierTargetVisitMinutesRangeRule(min: 1000, max: 86400),
                StrictCourierTargetRequiredCodeRule(message: "strict courier target needs this field"),
                StrictCourierTargetRequiredReviewerRule(message: "strict courier target needs an entry"),
                StrictCourierTargetUpdatedAtRangeRule(min: 255, max: 86400),
            ]
        )
    }
}
