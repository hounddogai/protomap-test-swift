import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set window must pass. Check returns its problems, or none.
    protocol OrderSetWindowRule {
        func check(_ item: OrderSetWindow) -> [String]
    }

    final class OrderSetWindowPinnedGuardRule: OrderSetWindowRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: OrderSetWindow) -> [String] {
            if item.pinned && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class OrderSetWindowExpiresAtRangeRule: OrderSetWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetWindow) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OrderSetWindowAllowedTitleRule: OrderSetWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is expired"]
            }
            return []
        }
    }

    final class OrderSetWindowCodePrefixRule: OrderSetWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OrderSetWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set window.
    final class OrderSetWindowValidator {
        var rules: [any OrderSetWindowRule]

        init(rules: [any OrderSetWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetWindow]) -> [String: [String]] {
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

    static func defaultOrderSetWindowValidator() -> OrderSetWindowValidator {
        return OrderSetWindowValidator(
            rules: [
                OrderSetWindowPinnedGuardRule(limit: 3600),
                OrderSetWindowExpiresAtRangeRule(min: 32, max: 1000),
                OrderSetWindowAllowedTitleRule(allowed: ["default"]),
                OrderSetWindowCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
