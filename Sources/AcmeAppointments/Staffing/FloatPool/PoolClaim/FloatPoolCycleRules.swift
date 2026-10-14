import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool cycle must pass. Check returns its problems, or none.
    protocol FloatPoolCycleRule {
        func check(_ item: FloatPoolCycle) -> [String]
    }

    final class FloatPoolCycleCodeLengthRule: FloatPoolCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolCycleRequiredCodeRule: FloatPoolCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolCycleCostRangeRule: FloatPoolCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolCycle) -> [String] {
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

    final class FloatPoolCycleNameLengthRule: FloatPoolCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolCycleRequiredNameRule: FloatPoolCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolCycleRefillsRangeRule: FloatPoolCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolCycle) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a float pool cycle.
    final class FloatPoolCycleValidator {
        var rules: [any FloatPoolCycleRule]

        init(rules: [any FloatPoolCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolCycle]) -> [String: [String]] {
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

    static func defaultFloatPoolCycleValidator() -> FloatPoolCycleValidator {
        return FloatPoolCycleValidator(
            rules: [
                FloatPoolCycleCodeLengthRule(maxLength: 32),
                FloatPoolCycleRequiredCodeRule(message: "float pool cycle needs this field"),
                FloatPoolCycleCostRangeRule(min: 4.9, max: 3843.3),
                FloatPoolCycleNameLengthRule(maxLength: 86400),
                FloatPoolCycleRequiredNameRule(message: "float pool cycle needs an entry"),
                FloatPoolCycleRefillsRangeRule(min: 64, max: 3600),
            ]
        )
    }
}
