import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility exception must pass. Check returns its problems, or none.
    protocol EligibilityExceptionRule {
        func check(_ item: EligibilityException) -> [String]
    }

    final class EligibilityExceptionRequiredCodeRule: EligibilityExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityExceptionCountryLengthRule: EligibilityExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityException) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityExceptionMaximumRangeRule: EligibilityExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityException) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class EligibilityExceptionCodeLengthRule: EligibilityExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityExceptionRequiredCountryRule: EligibilityExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityException) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityExceptionAllowedCodeRule: EligibilityExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility exception.
    final class EligibilityExceptionValidator {
        var rules: [any EligibilityExceptionRule]

        init(rules: [any EligibilityExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityException) -> [String] {
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

        func requireValid(_ item: EligibilityException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityException]) -> [String: [String]] {
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

    static func defaultEligibilityExceptionValidator() -> EligibilityExceptionValidator {
        return EligibilityExceptionValidator(
            rules: [
                EligibilityExceptionRequiredCodeRule(message: "eligibility exception needs a value"),
                EligibilityExceptionCountryLengthRule(maxLength: 3600),
                EligibilityExceptionMaximumRangeRule(min: 6.5, max: 1473.4),
                EligibilityExceptionCodeLengthRule(maxLength: 1000),
                EligibilityExceptionRequiredCountryRule(message: "eligibility exception needs a value"),
                EligibilityExceptionAllowedCodeRule(allowed: ["lenient", "fallback", "legacy"]),
            ]
        )
    }
}
