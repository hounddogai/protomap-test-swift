import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped risk score claim must pass. Check returns its problems, or none.
    protocol CappedRiskScoreClaimRule {
        func check(_ item: CappedRiskScoreClaim) -> [String]
    }

    final class CappedRiskScoreClaimRequiredCategoryRule: CappedRiskScoreClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRiskScoreClaim) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRiskScoreClaimCodePrefixRule: CappedRiskScoreClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedRiskScoreClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedRiskScoreClaimCodeLengthRule: CappedRiskScoreClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRiskScoreClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRiskScoreClaimRequiredContactEmailRule: CappedRiskScoreClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRiskScoreClaim) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRiskScoreClaimRequiredCodeRule: CappedRiskScoreClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRiskScoreClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped risk score claim.
    final class CappedRiskScoreClaimValidator {
        var rules: [any CappedRiskScoreClaimRule]

        init(rules: [any CappedRiskScoreClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRiskScoreClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedRiskScoreClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRiskScoreClaim]) -> [String: [String]] {
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

    static func defaultCappedRiskScoreClaimValidator() -> CappedRiskScoreClaimValidator {
        return CappedRiskScoreClaimValidator(
            rules: [
                CappedRiskScoreClaimRequiredCategoryRule(message: "capped risk score claim needs a value"),
                CappedRiskScoreClaimCodePrefixRule(prefix: "ACM"),
                CappedRiskScoreClaimCodeLengthRule(maxLength: 255),
                CappedRiskScoreClaimRequiredContactEmailRule(message: "capped risk score claim needs an entry"),
                CappedRiskScoreClaimRequiredCodeRule(message: "capped risk score claim needs an entry"),
            ]
        )
    }
}
