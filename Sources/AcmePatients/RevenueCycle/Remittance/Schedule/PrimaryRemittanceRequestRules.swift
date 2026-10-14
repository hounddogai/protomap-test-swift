import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary remittance request must pass. Check returns its problems, or none.
    protocol PrimaryRemittanceRequestRule {
        func check(_ item: PrimaryRemittanceRequest) -> [String]
    }

    final class PrimaryRemittanceRequestRequiredCurrencyRule: PrimaryRemittanceRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRemittanceRequest) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRemittanceRequestAmountRangeRule: PrimaryRemittanceRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRemittanceRequest) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryRemittanceRequestRequiredCodeRule: PrimaryRemittanceRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRemittanceRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary remittance request.
    final class PrimaryRemittanceRequestValidator {
        var rules: [any PrimaryRemittanceRequestRule]

        init(rules: [any PrimaryRemittanceRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryRemittanceRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryRemittanceRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryRemittanceRequest]) -> [String: [String]] {
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

    static func defaultPrimaryRemittanceRequestValidator() -> PrimaryRemittanceRequestValidator {
        return PrimaryRemittanceRequestValidator(
            rules: [
                PrimaryRemittanceRequestRequiredCurrencyRule(message: "primary remittance request needs a value"),
                PrimaryRemittanceRequestAmountRangeRule(min: 7.1, max: 1356.1),
                PrimaryRemittanceRequestRequiredCodeRule(message: "primary remittance request needs an entry"),
            ]
        )
    }
}
