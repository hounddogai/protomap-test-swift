import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense variance must pass. Check returns its problems, or none.
    protocol DispenseVarianceRule {
        func check(_ item: DispenseVariance) -> [String]
    }

    final class DispenseVarianceRequiredPhoneRule: DispenseVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseVariance) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseVarianceQuantityRangeRule: DispenseVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseVariance) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseVarianceAllowedNameRule: DispenseVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is expired"]
            }
            return []
        }
    }

    final class DispenseVarianceActiveGuardRule: DispenseVarianceRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DispenseVariance) -> [String] {
            if item.active && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense variance.
    final class DispenseVarianceValidator {
        var rules: [any DispenseVarianceRule]

        init(rules: [any DispenseVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseVariance]) -> [String: [String]] {
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

    static func defaultDispenseVarianceValidator() -> DispenseVarianceValidator {
        return DispenseVarianceValidator(
            rules: [
                DispenseVarianceRequiredPhoneRule(message: "dispense variance needs a value"),
                DispenseVarianceQuantityRangeRule(min: 64, max: 255),
                DispenseVarianceAllowedNameRule(allowed: ["pending", "tiered", "primary"]),
                DispenseVarianceActiveGuardRule(limit: 6.4),
            ]
        )
    }
}
