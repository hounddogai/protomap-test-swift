import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set request must pass. Check returns its problems, or none.
    protocol OrderSetRequestRule {
        func check(_ item: OrderSetRequest) -> [String]
    }

    final class OrderSetRequestAmountRangeRule: OrderSetRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetRequest) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetRequestAllowedCodeRule: OrderSetRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class OrderSetRequestProcedureCodeLengthRule: OrderSetRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetRequest) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set request.
    final class OrderSetRequestValidator {
        var rules: [any OrderSetRequestRule]

        init(rules: [any OrderSetRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetRequest) -> [String] {
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

        func requireValid(_ item: OrderSetRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetRequest]) -> [String: [String]] {
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

    static func defaultOrderSetRequestValidator() -> OrderSetRequestValidator {
        return OrderSetRequestValidator(
            rules: [
                OrderSetRequestAmountRangeRule(min: 5.3, max: 3939.4),
                OrderSetRequestAllowedCodeRule(allowed: ["strict", "capped", "rolling"]),
                OrderSetRequestProcedureCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
