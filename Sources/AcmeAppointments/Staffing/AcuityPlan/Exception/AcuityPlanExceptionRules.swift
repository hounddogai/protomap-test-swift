import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan exception must pass. Check returns its problems, or none.
    protocol AcuityPlanExceptionRule {
        func check(_ item: AcuityPlanException) -> [String]
    }

    final class AcuityPlanExceptionCapacityRangeRule: AcuityPlanExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanException) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AcuityPlanExceptionCodeLengthRule: AcuityPlanExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanExceptionNameLengthRule: AcuityPlanExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanException) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan exception.
    final class AcuityPlanExceptionValidator {
        var rules: [any AcuityPlanExceptionRule]

        init(rules: [any AcuityPlanExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AcuityPlanException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanException]) -> [String: [String]] {
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

    static func defaultAcuityPlanExceptionValidator() -> AcuityPlanExceptionValidator {
        return AcuityPlanExceptionValidator(
            rules: [
                AcuityPlanExceptionCapacityRangeRule(min: 1000, max: 3600),
                AcuityPlanExceptionCodeLengthRule(maxLength: 32),
                AcuityPlanExceptionNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
