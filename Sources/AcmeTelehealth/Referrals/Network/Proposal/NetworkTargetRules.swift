import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network target must pass. Check returns its problems, or none.
    protocol NetworkTargetRule {
        func check(_ item: NetworkTarget) -> [String]
    }

    final class NetworkTargetRequiredCodeRule: NetworkTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkTargetRevisionRangeRule: NetworkTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkTarget) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class NetworkTargetQuantityRangeRule: NetworkTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkTarget) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a network target.
    final class NetworkTargetValidator {
        var rules: [any NetworkTargetRule]

        init(rules: [any NetworkTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkTarget]) -> [String: [String]] {
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

    static func defaultNetworkTargetValidator() -> NetworkTargetValidator {
        return NetworkTargetValidator(
            rules: [
                NetworkTargetRequiredCodeRule(message: "network target needs a value"),
                NetworkTargetRevisionRangeRule(min: 16, max: 255),
                NetworkTargetQuantityRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
