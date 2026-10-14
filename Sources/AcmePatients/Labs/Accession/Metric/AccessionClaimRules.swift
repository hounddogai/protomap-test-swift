import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession claim must pass. Check returns its problems, or none.
    protocol AccessionClaimRule {
        func check(_ item: AccessionClaim) -> [String]
    }

    final class AccessionClaimCodePrefixRule: AccessionClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AccessionClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AccessionClaimRequiredSegmentRule: AccessionClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionClaim) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionClaimRequiredAllergyRule: AccessionClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionClaim) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a accession claim.
    final class AccessionClaimValidator {
        var rules: [any AccessionClaimRule]

        init(rules: [any AccessionClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionClaim]) -> [String: [String]] {
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

    static func defaultAccessionClaimValidator() -> AccessionClaimValidator {
        return AccessionClaimValidator(
            rules: [
                AccessionClaimCodePrefixRule(prefix: "ACM"),
                AccessionClaimRequiredSegmentRule(message: "accession claim needs an entry"),
                AccessionClaimRequiredAllergyRule(message: "accession claim needs a value"),
            ]
        )
    }
}
