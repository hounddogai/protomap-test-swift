import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network baseline must pass. Check returns its problems, or none.
    protocol NetworkBaselineRule {
        func check(_ item: NetworkBaseline) -> [String]
    }

    final class NetworkBaselineRequiredLabelRule: NetworkBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkBaselineRequiredCodeRule: NetworkBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkBaselineStartsAtRangeRule: NetworkBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkBaseline) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkBaselineCostRangeRule: NetworkBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkBaseline) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class NetworkBaselineCodePrefixRule: NetworkBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: NetworkBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a network baseline.
    final class NetworkBaselineValidator {
        var rules: [any NetworkBaselineRule]

        init(rules: [any NetworkBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkBaseline) -> [String] {
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

        func requireValid(_ item: NetworkBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkBaseline]) -> [String: [String]] {
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

    static func defaultNetworkBaselineValidator() -> NetworkBaselineValidator {
        return NetworkBaselineValidator(
            rules: [
                NetworkBaselineRequiredLabelRule(message: "network baseline needs an entry"),
                NetworkBaselineRequiredCodeRule(message: "network baseline needs this field"),
                NetworkBaselineStartsAtRangeRule(min: 64, max: 80),
                NetworkBaselineCostRangeRule(min: 9.6, max: 1529.8),
                NetworkBaselineCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
