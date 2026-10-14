import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim estimate must pass. Check returns its problems, or none.
    protocol ClaimEstimateRule {
        func check(_ item: ClaimEstimate) -> [String]
    }

    final class ClaimEstimateRequiredCodeRule: ClaimEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimEstimateCodeLengthRule: ClaimEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimEstimateRequiredUnitRule: ClaimEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimEstimate) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimEstimateAllowedUnitRule: ClaimEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a claim estimate.
    final class ClaimEstimateValidator {
        var rules: [any ClaimEstimateRule]

        init(rules: [any ClaimEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimEstimate) -> [String] {
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

        func requireValid(_ item: ClaimEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimEstimate]) -> [String: [String]] {
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

    static func defaultClaimEstimateValidator() -> ClaimEstimateValidator {
        return ClaimEstimateValidator(
            rules: [
                ClaimEstimateRequiredCodeRule(message: "claim estimate needs this field"),
                ClaimEstimateCodeLengthRule(maxLength: 80),
                ClaimEstimateRequiredUnitRule(message: "claim estimate needs this field"),
                ClaimEstimateAllowedUnitRule(allowed: ["default", "fallback"]),
            ]
        )
    }
}
