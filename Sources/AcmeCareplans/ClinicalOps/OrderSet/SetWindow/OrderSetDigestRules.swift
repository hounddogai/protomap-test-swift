import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set digest must pass. Check returns its problems, or none.
    protocol OrderSetDigestRule {
        func check(_ item: OrderSetDigest) -> [String]
    }

    final class OrderSetDigestRequiredRegionRule: OrderSetDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetDigest) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetDigestWindowDaysRangeRule: OrderSetDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetDigest) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OrderSetDigestAllowedAllergyRule: OrderSetDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is too long"]
            }
            return []
        }
    }

    final class OrderSetDigestCodeLengthRule: OrderSetDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetDigestRequiredCurrencyRule: OrderSetDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetDigest) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetDigestRequiredCodeRule: OrderSetDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set digest.
    final class OrderSetDigestValidator {
        var rules: [any OrderSetDigestRule]

        init(rules: [any OrderSetDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetDigest]) -> [String: [String]] {
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

    static func defaultOrderSetDigestValidator() -> OrderSetDigestValidator {
        return OrderSetDigestValidator(
            rules: [
                OrderSetDigestRequiredRegionRule(message: "order set digest needs this field"),
                OrderSetDigestWindowDaysRangeRule(min: 64, max: 80),
                OrderSetDigestAllowedAllergyRule(allowed: ["rolling", "tiered", "legacy"]),
                OrderSetDigestCodeLengthRule(maxLength: 86400),
                OrderSetDigestRequiredCurrencyRule(message: "order set digest needs this field"),
                OrderSetDigestRequiredCodeRule(message: "order set digest needs an entry"),
            ]
        )
    }
}
