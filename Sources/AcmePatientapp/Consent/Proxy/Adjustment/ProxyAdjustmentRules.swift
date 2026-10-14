import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy adjustment must pass. Check returns its problems, or none.
    protocol ProxyAdjustmentRule {
        func check(_ item: ProxyAdjustment) -> [String]
    }

    final class ProxyAdjustmentDiscountRangeRule: ProxyAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyAdjustment) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProxyAdjustmentRequiredTitleRule: ProxyAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyAdjustment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyAdjustmentAllowedTitleRule: ProxyAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy adjustment.
    final class ProxyAdjustmentValidator {
        var rules: [any ProxyAdjustmentRule]

        init(rules: [any ProxyAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyAdjustment]) -> [String: [String]] {
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

    static func defaultProxyAdjustmentValidator() -> ProxyAdjustmentValidator {
        return ProxyAdjustmentValidator(
            rules: [
                ProxyAdjustmentDiscountRangeRule(min: 1.3, max: 4619.2),
                ProxyAdjustmentRequiredTitleRule(message: "proxy adjustment needs an entry"),
                ProxyAdjustmentAllowedTitleRule(allowed: ["legacy", "manual"]),
            ]
        )
    }
}
