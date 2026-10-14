import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary shift allocation must pass. Check returns its problems, or none.
    protocol PrimaryShiftAllocationRule {
        func check(_ item: PrimaryShiftAllocation) -> [String]
    }

    final class PrimaryShiftAllocationTitleLengthRule: PrimaryShiftAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryShiftAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryShiftAllocationPhoneLengthRule: PrimaryShiftAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryShiftAllocation) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryShiftAllocationBudgetRangeRule: PrimaryShiftAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryShiftAllocation) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary shift allocation.
    final class PrimaryShiftAllocationValidator {
        var rules: [any PrimaryShiftAllocationRule]

        init(rules: [any PrimaryShiftAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryShiftAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryShiftAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryShiftAllocation]) -> [String: [String]] {
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

    static func defaultPrimaryShiftAllocationValidator() -> PrimaryShiftAllocationValidator {
        return PrimaryShiftAllocationValidator(
            rules: [
                PrimaryShiftAllocationTitleLengthRule(maxLength: 120),
                PrimaryShiftAllocationPhoneLengthRule(maxLength: 64),
                PrimaryShiftAllocationBudgetRangeRule(min: 2.0, max: 4838.6),
            ]
        )
    }
}
