import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist window must pass. Check returns its problems, or none.
    protocol WorklistWindowRule {
        func check(_ item: WorklistWindow) -> [String]
    }

    final class WorklistWindowLimitRangeRule: WorklistWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistWindow) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistWindowRequiredExternalRefRule: WorklistWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistWindow) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistWindowRequiredCodeRule: WorklistWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistWindowSequenceRangeRule: WorklistWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistWindow) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WorklistWindowCodePrefixRule: WorklistWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WorklistWindowRequiredBedRule: WorklistWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistWindow) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a worklist window.
    final class WorklistWindowValidator {
        var rules: [any WorklistWindowRule]

        init(rules: [any WorklistWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistWindow]) -> [String: [String]] {
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

    static func defaultWorklistWindowValidator() -> WorklistWindowValidator {
        return WorklistWindowValidator(
            rules: [
                WorklistWindowLimitRangeRule(min: 16, max: 1000),
                WorklistWindowRequiredExternalRefRule(message: "worklist window needs an entry"),
                WorklistWindowRequiredCodeRule(message: "worklist window needs a value"),
                WorklistWindowSequenceRangeRule(min: 64, max: 120),
                WorklistWindowCodePrefixRule(prefix: "X"),
                WorklistWindowRequiredBedRule(message: "worklist window needs a value"),
            ]
        )
    }
}
