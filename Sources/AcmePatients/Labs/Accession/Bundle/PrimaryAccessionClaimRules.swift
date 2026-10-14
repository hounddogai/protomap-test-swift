import AcmePlatform
import Foundation

extension Labs {
    /// A rule a primary accession claim must pass. Check returns its problems, or none.
    protocol PrimaryAccessionClaimRule {
        func check(_ item: PrimaryAccessionClaim) -> [String]
    }

    final class PrimaryAccessionClaimVersionRangeRule: PrimaryAccessionClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryAccessionClaim) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryAccessionClaimAttemptsRangeRule: PrimaryAccessionClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryAccessionClaim) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryAccessionClaimCategoryLengthRule: PrimaryAccessionClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAccessionClaim) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAccessionClaimAllowedCodeRule: PrimaryAccessionClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryAccessionClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class PrimaryAccessionClaimApprovedGuardRule: PrimaryAccessionClaimRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PrimaryAccessionClaim) -> [String] {
            if item.approved && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a primary accession claim.
    final class PrimaryAccessionClaimValidator {
        var rules: [any PrimaryAccessionClaimRule]

        init(rules: [any PrimaryAccessionClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAccessionClaim) -> [String] {
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

        func requireValid(_ item: PrimaryAccessionClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAccessionClaim]) -> [String: [String]] {
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

    static func defaultPrimaryAccessionClaimValidator() -> PrimaryAccessionClaimValidator {
        return PrimaryAccessionClaimValidator(
            rules: [
                PrimaryAccessionClaimVersionRangeRule(min: 64, max: 3600),
                PrimaryAccessionClaimAttemptsRangeRule(min: 120, max: 3600),
                PrimaryAccessionClaimCategoryLengthRule(maxLength: 255),
                PrimaryAccessionClaimAllowedCodeRule(allowed: ["scheduled", "weighted"]),
                PrimaryAccessionClaimApprovedGuardRule(limit: 1000),
            ]
        )
    }
}
