import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result allocation must pass. Check returns its problems, or none.
    protocol ResultAllocationRule {
        func check(_ item: ResultAllocation) -> [String]
    }

    final class ResultAllocationScoreRangeRule: ResultAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultAllocation) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ResultAllocationVisibleGuardRule: ResultAllocationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ResultAllocation) -> [String] {
            if item.visible && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ResultAllocationRequiredCodeRule: ResultAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultAllocationRequiredTitleRule: ResultAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultAllocation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a result allocation.
    final class ResultAllocationValidator {
        var rules: [any ResultAllocationRule]

        init(rules: [any ResultAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultAllocation) -> [String] {
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

        func requireValid(_ item: ResultAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultAllocation]) -> [String: [String]] {
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

    static func defaultResultAllocationValidator() -> ResultAllocationValidator {
        return ResultAllocationValidator(
            rules: [
                ResultAllocationScoreRangeRule(min: 3.2, max: 2781.4),
                ResultAllocationVisibleGuardRule(limit: 0.5),
                ResultAllocationRequiredCodeRule(message: "result allocation needs a value"),
                ResultAllocationRequiredTitleRule(message: "result allocation needs an entry"),
            ]
        )
    }
}
