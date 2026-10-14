import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense policy must pass. Check returns its problems, or none.
    protocol DispensePolicyRule {
        func check(_ item: DispensePolicy) -> [String]
    }

    final class DispensePolicySequenceRangeRule: DispensePolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispensePolicy) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispensePolicyContactEmailLengthRule: DispensePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispensePolicy) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispensePolicyAllowedPayerRule: DispensePolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispensePolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is expired"]
            }
            return []
        }
    }

    final class DispensePolicyCodeLengthRule: DispensePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispensePolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispensePolicyApprovedGuardRule: DispensePolicyRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DispensePolicy) -> [String] {
            if item.approved && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense policy.
    final class DispensePolicyValidator {
        var rules: [any DispensePolicyRule]

        init(rules: [any DispensePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: DispensePolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispensePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispensePolicy]) -> [String: [String]] {
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

    static func defaultDispensePolicyValidator() -> DispensePolicyValidator {
        return DispensePolicyValidator(
            rules: [
                DispensePolicySequenceRangeRule(min: 16, max: 3600),
                DispensePolicyContactEmailLengthRule(maxLength: 64),
                DispensePolicyAllowedPayerRule(allowed: ["rolling", "batched", "default"]),
                DispensePolicyCodeLengthRule(maxLength: 86400),
                DispensePolicyApprovedGuardRule(limit: 1.7),
            ]
        )
    }
}
