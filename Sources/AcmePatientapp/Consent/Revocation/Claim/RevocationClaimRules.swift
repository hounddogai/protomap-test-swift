import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation claim must pass. Check returns its problems, or none.
    protocol RevocationClaimRule {
        func check(_ item: RevocationClaim) -> [String]
    }

    final class RevocationClaimCreatedAtRangeRule: RevocationClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationClaim) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RevocationClaimTitleLengthRule: RevocationClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationClaimTimezoneLengthRule: RevocationClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationClaim) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation claim.
    final class RevocationClaimValidator {
        var rules: [any RevocationClaimRule]

        init(rules: [any RevocationClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationClaim) -> [String] {
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

        func requireValid(_ item: RevocationClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationClaim]) -> [String: [String]] {
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

    static func defaultRevocationClaimValidator() -> RevocationClaimValidator {
        return RevocationClaimValidator(
            rules: [
                RevocationClaimCreatedAtRangeRule(min: 16, max: 16),
                RevocationClaimTitleLengthRule(maxLength: 64),
                RevocationClaimTimezoneLengthRule(maxLength: 120),
            ]
        )
    }
}
