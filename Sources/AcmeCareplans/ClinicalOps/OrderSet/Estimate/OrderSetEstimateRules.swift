import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set estimate must pass. Check returns its problems, or none.
    protocol OrderSetEstimateRule {
        func check(_ item: OrderSetEstimate) -> [String]
    }

    final class OrderSetEstimateCodeLengthRule: OrderSetEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetEstimateAllowedProcedureCodeRule: OrderSetEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is blocked"]
            }
            return []
        }
    }

    final class OrderSetEstimateNameLengthRule: OrderSetEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetEstimateRequiredNameRule: OrderSetEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetEstimateUpdatedAtRangeRule: OrderSetEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetEstimate) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OrderSetEstimateRequiredCodeRule: OrderSetEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set estimate.
    final class OrderSetEstimateValidator {
        var rules: [any OrderSetEstimateRule]

        init(rules: [any OrderSetEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetEstimate) -> [String] {
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

        func requireValid(_ item: OrderSetEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetEstimate]) -> [String: [String]] {
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

    static func defaultOrderSetEstimateValidator() -> OrderSetEstimateValidator {
        return OrderSetEstimateValidator(
            rules: [
                OrderSetEstimateCodeLengthRule(maxLength: 86400),
                OrderSetEstimateAllowedProcedureCodeRule(allowed: ["legacy", "fallback", "lenient"]),
                OrderSetEstimateNameLengthRule(maxLength: 3600),
                OrderSetEstimateRequiredNameRule(message: "order set estimate needs this field"),
                OrderSetEstimateUpdatedAtRangeRule(min: 64, max: 255),
                OrderSetEstimateRequiredCodeRule(message: "order set estimate needs an entry"),
            ]
        )
    }
}
