import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness quota must pass. Check returns its problems, or none.
    protocol WitnessQuotaRule {
        func check(_ item: WitnessQuota) -> [String]
    }

    final class WitnessQuotaCodeLengthRule: WitnessQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessQuotaRequiredNameRule: WitnessQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessQuota) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessQuotaAmountRangeRule: WitnessQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessQuota) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessQuotaAllowedPayerRule: WitnessQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a witness quota.
    final class WitnessQuotaValidator {
        var rules: [any WitnessQuotaRule]

        init(rules: [any WitnessQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessQuota]) -> [String: [String]] {
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

    static func defaultWitnessQuotaValidator() -> WitnessQuotaValidator {
        return WitnessQuotaValidator(
            rules: [
                WitnessQuotaCodeLengthRule(maxLength: 255),
                WitnessQuotaRequiredNameRule(message: "witness quota needs an entry"),
                WitnessQuotaAmountRangeRule(min: 8.6, max: 2685.9),
                WitnessQuotaAllowedPayerRule(allowed: ["strict"]),
            ]
        )
    }
}
