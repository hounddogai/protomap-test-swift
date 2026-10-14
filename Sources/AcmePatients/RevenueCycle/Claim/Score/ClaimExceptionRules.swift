import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim exception must pass. Check returns its problems, or none.
    protocol ClaimExceptionRule {
        func check(_ item: ClaimException) -> [String]
    }

    final class ClaimExceptionAcuityRangeRule: ClaimExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimException) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimExceptionAllowedCodeRule: ClaimExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class ClaimExceptionExternalRefLengthRule: ClaimExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimException) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimExceptionDiscountRangeRule: ClaimExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimException) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimExceptionRequiredTitleRule: ClaimExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimException) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a claim exception.
    final class ClaimExceptionValidator {
        var rules: [any ClaimExceptionRule]

        init(rules: [any ClaimExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimException]) -> [String: [String]] {
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

    static func defaultClaimExceptionValidator() -> ClaimExceptionValidator {
        return ClaimExceptionValidator(
            rules: [
                ClaimExceptionAcuityRangeRule(min: 16, max: 32),
                ClaimExceptionAllowedCodeRule(allowed: ["strict", "scheduled"]),
                ClaimExceptionExternalRefLengthRule(maxLength: 86400),
                ClaimExceptionDiscountRangeRule(min: 9.4, max: 341.3),
                ClaimExceptionRequiredTitleRule(message: "claim exception needs this field"),
            ]
        )
    }
}
