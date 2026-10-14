import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted network quota must pass. Check returns its problems, or none.
    protocol WeightedNetworkQuotaRule {
        func check(_ item: WeightedNetworkQuota) -> [String]
    }

    final class WeightedNetworkQuotaCostRangeRule: WeightedNetworkQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedNetworkQuota) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedNetworkQuotaRequiredCodeRule: WeightedNetworkQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedNetworkQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedNetworkQuotaNameLengthRule: WeightedNetworkQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedNetworkQuota) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedNetworkQuotaMarginRangeRule: WeightedNetworkQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedNetworkQuota) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedNetworkQuotaCodeLengthRule: WeightedNetworkQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedNetworkQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted network quota.
    final class WeightedNetworkQuotaValidator {
        var rules: [any WeightedNetworkQuotaRule]

        init(rules: [any WeightedNetworkQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedNetworkQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedNetworkQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedNetworkQuota]) -> [String: [String]] {
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

    static func defaultWeightedNetworkQuotaValidator() -> WeightedNetworkQuotaValidator {
        return WeightedNetworkQuotaValidator(
            rules: [
                WeightedNetworkQuotaCostRangeRule(min: 4.6, max: 3964.2),
                WeightedNetworkQuotaRequiredCodeRule(message: "weighted network quota needs a value"),
                WeightedNetworkQuotaNameLengthRule(maxLength: 80),
                WeightedNetworkQuotaMarginRangeRule(min: 4.5, max: 336.8),
                WeightedNetworkQuotaCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
