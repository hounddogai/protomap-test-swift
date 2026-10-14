import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default network window must pass. Check returns its problems, or none.
    protocol DefaultNetworkWindowRule {
        func check(_ item: DefaultNetworkWindow) -> [String]
    }

    final class DefaultNetworkWindowDiscountRangeRule: DefaultNetworkWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultNetworkWindow) -> [String] {
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

    final class DefaultNetworkWindowActiveGuardRule: DefaultNetworkWindowRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultNetworkWindow) -> [String] {
            if item.active && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class DefaultNetworkWindowCodePrefixRule: DefaultNetworkWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultNetworkWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultNetworkWindowRequiredCodeRule: DefaultNetworkWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultNetworkWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultNetworkWindowRequiredContactEmailRule: DefaultNetworkWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultNetworkWindow) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default network window.
    final class DefaultNetworkWindowValidator {
        var rules: [any DefaultNetworkWindowRule]

        init(rules: [any DefaultNetworkWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultNetworkWindow) -> [String] {
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

        func requireValid(_ item: DefaultNetworkWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultNetworkWindow]) -> [String: [String]] {
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

    static func defaultDefaultNetworkWindowValidator() -> DefaultNetworkWindowValidator {
        return DefaultNetworkWindowValidator(
            rules: [
                DefaultNetworkWindowDiscountRangeRule(min: 3.0, max: 4265.9),
                DefaultNetworkWindowActiveGuardRule(limit: 64),
                DefaultNetworkWindowCodePrefixRule(prefix: "Q"),
                DefaultNetworkWindowRequiredCodeRule(message: "default network window needs an entry"),
                DefaultNetworkWindowRequiredContactEmailRule(message: "default network window needs an entry"),
            ]
        )
    }
}
