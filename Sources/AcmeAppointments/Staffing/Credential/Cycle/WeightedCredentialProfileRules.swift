import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a weighted credential profile must pass. Check returns its problems, or none.
    protocol WeightedCredentialProfileRule {
        func check(_ item: WeightedCredentialProfile) -> [String]
    }

    final class WeightedCredentialProfileRequiredCodeRule: WeightedCredentialProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCredentialProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCredentialProfileCodePrefixRule: WeightedCredentialProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedCredentialProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedCredentialProfileLimitRangeRule: WeightedCredentialProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCredentialProfile) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedCredentialProfileQuantityRangeRule: WeightedCredentialProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCredentialProfile) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedCredentialProfileFloorValueRangeRule: WeightedCredentialProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCredentialProfile) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted credential profile.
    final class WeightedCredentialProfileValidator {
        var rules: [any WeightedCredentialProfileRule]

        init(rules: [any WeightedCredentialProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCredentialProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedCredentialProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCredentialProfile]) -> [String: [String]] {
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

    static func defaultWeightedCredentialProfileValidator() -> WeightedCredentialProfileValidator {
        return WeightedCredentialProfileValidator(
            rules: [
                WeightedCredentialProfileRequiredCodeRule(message: "weighted credential profile needs a value"),
                WeightedCredentialProfileCodePrefixRule(prefix: "Q"),
                WeightedCredentialProfileLimitRangeRule(min: 16, max: 80),
                WeightedCredentialProfileQuantityRangeRule(min: 80, max: 120),
                WeightedCredentialProfileFloorValueRangeRule(min: 4.2, max: 4346.4),
            ]
        )
    }
}
