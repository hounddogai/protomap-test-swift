import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped eligibility mapping must pass. Check returns its problems, or none.
    protocol CappedEligibilityMappingRule {
        func check(_ item: CappedEligibilityMapping) -> [String]
    }

    final class CappedEligibilityMappingRequiredTitleRule: CappedEligibilityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedEligibilityMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedEligibilityMappingAllowedWardRule: CappedEligibilityMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedEligibilityMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is too long"]
            }
            return []
        }
    }

    final class CappedEligibilityMappingCodePrefixRule: CappedEligibilityMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedEligibilityMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped eligibility mapping.
    final class CappedEligibilityMappingValidator {
        var rules: [any CappedEligibilityMappingRule]

        init(rules: [any CappedEligibilityMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedEligibilityMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedEligibilityMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedEligibilityMapping]) -> [String: [String]] {
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

    static func defaultCappedEligibilityMappingValidator() -> CappedEligibilityMappingValidator {
        return CappedEligibilityMappingValidator(
            rules: [
                CappedEligibilityMappingRequiredTitleRule(message: "capped eligibility mapping needs a value"),
                CappedEligibilityMappingAllowedWardRule(allowed: []),
                CappedEligibilityMappingCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
