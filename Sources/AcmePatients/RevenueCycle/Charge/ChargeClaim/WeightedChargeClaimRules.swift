import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted charge claim must pass. Check returns its problems, or none.
    protocol WeightedChargeClaimRule {
        func check(_ item: WeightedChargeClaim) -> [String]
    }

    final class WeightedChargeClaimContactEmailLengthRule: WeightedChargeClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedChargeClaim) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedChargeClaimRequiredContactEmailRule: WeightedChargeClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedChargeClaim) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedChargeClaimEndsAtRangeRule: WeightedChargeClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedChargeClaim) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted charge claim.
    final class WeightedChargeClaimValidator {
        var rules: [any WeightedChargeClaimRule]

        init(rules: [any WeightedChargeClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedChargeClaim) -> [String] {
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

        func requireValid(_ item: WeightedChargeClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedChargeClaim]) -> [String: [String]] {
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

    static func defaultWeightedChargeClaimValidator() -> WeightedChargeClaimValidator {
        return WeightedChargeClaimValidator(
            rules: [
                WeightedChargeClaimContactEmailLengthRule(maxLength: 64),
                WeightedChargeClaimRequiredContactEmailRule(message: "weighted charge claim needs an entry"),
                WeightedChargeClaimEndsAtRangeRule(min: 16, max: 80),
            ]
        )
    }
}
