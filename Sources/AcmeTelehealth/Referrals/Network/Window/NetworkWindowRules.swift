import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network window must pass. Check returns its problems, or none.
    protocol NetworkWindowRule {
        func check(_ item: NetworkWindow) -> [String]
    }

    final class NetworkWindowCodePrefixRule: NetworkWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: NetworkWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class NetworkWindowBatchSizeRangeRule: NetworkWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkWindow) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class NetworkWindowRefillsRangeRule: NetworkWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkWindow) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkWindowCreatedAtRangeRule: NetworkWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkWindow) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class NetworkWindowQuantityRangeRule: NetworkWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkWindow) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a network window.
    final class NetworkWindowValidator {
        var rules: [any NetworkWindowRule]

        init(rules: [any NetworkWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkWindow) -> [String] {
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

        func requireValid(_ item: NetworkWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkWindow]) -> [String: [String]] {
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

    static func defaultNetworkWindowValidator() -> NetworkWindowValidator {
        return NetworkWindowValidator(
            rules: [
                NetworkWindowCodePrefixRule(prefix: "ACM"),
                NetworkWindowBatchSizeRangeRule(min: 120, max: 86400),
                NetworkWindowRefillsRangeRule(min: 32, max: 120),
                NetworkWindowCreatedAtRangeRule(min: 64, max: 80),
                NetworkWindowQuantityRangeRule(min: 16, max: 255),
            ]
        )
    }
}
