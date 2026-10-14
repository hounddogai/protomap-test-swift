import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist cycle must pass. Check returns its problems, or none.
    protocol WorklistCycleRule {
        func check(_ item: WorklistCycle) -> [String]
    }

    final class WorklistCycleNameLengthRule: WorklistCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistCycleCostRangeRule: WorklistCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistCycle) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WorklistCycleCodeLengthRule: WorklistCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist cycle.
    final class WorklistCycleValidator {
        var rules: [any WorklistCycleRule]

        init(rules: [any WorklistCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistCycle]) -> [String: [String]] {
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

    static func defaultWorklistCycleValidator() -> WorklistCycleValidator {
        return WorklistCycleValidator(
            rules: [
                WorklistCycleNameLengthRule(maxLength: 3600),
                WorklistCycleCostRangeRule(min: 0.9, max: 2675.1),
                WorklistCycleCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
