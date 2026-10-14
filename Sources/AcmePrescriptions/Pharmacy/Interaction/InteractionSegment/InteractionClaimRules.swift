import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction claim must pass. Check returns its problems, or none.
    protocol InteractionClaimRule {
        func check(_ item: InteractionClaim) -> [String]
    }

    final class InteractionClaimDosageMgRangeRule: InteractionClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionClaim) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionClaimCodeLengthRule: InteractionClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionClaimRequiredTitleRule: InteractionClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionClaimTitleLengthRule: InteractionClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction claim.
    final class InteractionClaimValidator {
        var rules: [any InteractionClaimRule]

        init(rules: [any InteractionClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionClaim) -> [String] {
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

        func requireValid(_ item: InteractionClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionClaim]) -> [String: [String]] {
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

    static func defaultInteractionClaimValidator() -> InteractionClaimValidator {
        return InteractionClaimValidator(
            rules: [
                InteractionClaimDosageMgRangeRule(min: 4.8, max: 4386.8),
                InteractionClaimCodeLengthRule(maxLength: 255),
                InteractionClaimRequiredTitleRule(message: "interaction claim needs a value"),
                InteractionClaimTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
