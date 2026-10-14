import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set quota must pass. Check returns its problems, or none.
    protocol OrderSetQuotaRule {
        func check(_ item: OrderSetQuota) -> [String]
    }

    final class OrderSetQuotaQuantityRangeRule: OrderSetQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetQuota) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetQuotaRequiredCountryRule: OrderSetQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetQuota) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetQuotaCostRangeRule: OrderSetQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetQuota) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetQuotaCountryLengthRule: OrderSetQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetQuota) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set quota.
    final class OrderSetQuotaValidator {
        var rules: [any OrderSetQuotaRule]

        init(rules: [any OrderSetQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetQuota]) -> [String: [String]] {
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

    static func defaultOrderSetQuotaValidator() -> OrderSetQuotaValidator {
        return OrderSetQuotaValidator(
            rules: [
                OrderSetQuotaQuantityRangeRule(min: 120, max: 86400),
                OrderSetQuotaRequiredCountryRule(message: "order set quota needs an entry"),
                OrderSetQuotaCostRangeRule(min: 9.1, max: 3705.4),
                OrderSetQuotaCountryLengthRule(maxLength: 16),
            ]
        )
    }
}
