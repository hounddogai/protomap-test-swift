import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set allocation must pass. Check returns its problems, or none.
    protocol OrderSetAllocationRule {
        func check(_ item: OrderSetAllocation) -> [String]
    }

    final class OrderSetAllocationCodeLengthRule: OrderSetAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetAllocationFloorValueRangeRule: OrderSetAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetAllocation) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetAllocationRequiredCodeRule: OrderSetAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set allocation.
    final class OrderSetAllocationValidator {
        var rules: [any OrderSetAllocationRule]

        init(rules: [any OrderSetAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetAllocation]) -> [String: [String]] {
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

    static func defaultOrderSetAllocationValidator() -> OrderSetAllocationValidator {
        return OrderSetAllocationValidator(
            rules: [
                OrderSetAllocationCodeLengthRule(maxLength: 1000),
                OrderSetAllocationFloorValueRangeRule(min: 3.1, max: 2179.7),
                OrderSetAllocationRequiredCodeRule(message: "order set allocation needs this field"),
            ]
        )
    }
}
