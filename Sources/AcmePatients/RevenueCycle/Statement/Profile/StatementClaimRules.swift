import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement claim must pass. Check returns its problems, or none.
    protocol StatementClaimRule {
        func check(_ item: StatementClaim) -> [String]
    }

    final class StatementClaimCodeLengthRule: StatementClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementClaimRequiredContactEmailRule: StatementClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementClaim) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementClaimExternalRefLengthRule: StatementClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementClaim) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementClaimDiscountRangeRule: StatementClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementClaim) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementClaimRateRangeRule: StatementClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementClaim) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementClaimRetriesRangeRule: StatementClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementClaim) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a statement claim.
    final class StatementClaimValidator {
        var rules: [any StatementClaimRule]

        init(rules: [any StatementClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementClaim]) -> [String: [String]] {
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

    static func defaultStatementClaimValidator() -> StatementClaimValidator {
        return StatementClaimValidator(
            rules: [
                StatementClaimCodeLengthRule(maxLength: 1000),
                StatementClaimRequiredContactEmailRule(message: "statement claim needs an entry"),
                StatementClaimExternalRefLengthRule(maxLength: 255),
                StatementClaimDiscountRangeRule(min: 6.1, max: 4180.4),
                StatementClaimRateRangeRule(min: 0.2, max: 3805.8),
                StatementClaimRetriesRangeRule(min: 32, max: 255),
            ]
        )
    }
}
