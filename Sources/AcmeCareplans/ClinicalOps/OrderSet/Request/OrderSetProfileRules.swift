import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set profile must pass. Check returns its problems, or none.
    protocol OrderSetProfileRule {
        func check(_ item: OrderSetProfile) -> [String]
    }

    final class OrderSetProfileRateRangeRule: OrderSetProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetProfile) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetProfileCodePrefixRule: OrderSetProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OrderSetProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OrderSetProfileRequiredPhoneRule: OrderSetProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetProfile) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetProfileRequiredCodeRule: OrderSetProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetProfileAllowedPhoneRule: OrderSetProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a order set profile.
    final class OrderSetProfileValidator {
        var rules: [any OrderSetProfileRule]

        init(rules: [any OrderSetProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetProfile) -> [String] {
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

        func requireValid(_ item: OrderSetProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetProfile]) -> [String: [String]] {
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

    static func defaultOrderSetProfileValidator() -> OrderSetProfileValidator {
        return OrderSetProfileValidator(
            rules: [
                OrderSetProfileRateRangeRule(min: 3.1, max: 695.5),
                OrderSetProfileCodePrefixRule(prefix: "REF"),
                OrderSetProfileRequiredPhoneRule(message: "order set profile needs this field"),
                OrderSetProfileRequiredCodeRule(message: "order set profile needs this field"),
                OrderSetProfileAllowedPhoneRule(allowed: ["primary", "pending", "global"]),
            ]
        )
    }
}
