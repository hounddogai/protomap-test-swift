import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall target must pass. Check returns its problems, or none.
    protocol RecallTargetRule {
        func check(_ item: RecallTarget) -> [String]
    }

    final class RecallTargetVersionRangeRule: RecallTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallTarget) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallTargetRequiredCodeRule: RecallTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallTargetCreatedAtRangeRule: RecallTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallTarget) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RecallTargetStartsAtRangeRule: RecallTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallTarget) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a recall target.
    final class RecallTargetValidator {
        var rules: [any RecallTargetRule]

        init(rules: [any RecallTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallTarget) -> [String] {
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

        func requireValid(_ item: RecallTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallTarget]) -> [String: [String]] {
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

    static func defaultRecallTargetValidator() -> RecallTargetValidator {
        return RecallTargetValidator(
            rules: [
                RecallTargetVersionRangeRule(min: 16, max: 3600),
                RecallTargetRequiredCodeRule(message: "recall target needs a value"),
                RecallTargetCreatedAtRangeRule(min: 80, max: 1000),
                RecallTargetStartsAtRangeRule(min: 16, max: 255),
            ]
        )
    }
}
