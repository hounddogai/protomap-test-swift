import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback result claim must pass. Check returns its problems, or none.
    protocol FallbackResultClaimRule {
        func check(_ item: FallbackResultClaim) -> [String]
    }

    final class FallbackResultClaimCodePrefixRule: FallbackResultClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackResultClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackResultClaimCreatedAtRangeRule: FallbackResultClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackResultClaim) -> [String] {
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

    final class FallbackResultClaimSpecialtyLengthRule: FallbackResultClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackResultClaim) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback result claim.
    final class FallbackResultClaimValidator {
        var rules: [any FallbackResultClaimRule]

        init(rules: [any FallbackResultClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackResultClaim) -> [String] {
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

        func requireValid(_ item: FallbackResultClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackResultClaim]) -> [String: [String]] {
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

    static func defaultFallbackResultClaimValidator() -> FallbackResultClaimValidator {
        return FallbackResultClaimValidator(
            rules: [
                FallbackResultClaimCodePrefixRule(prefix: "OPS"),
                FallbackResultClaimCreatedAtRangeRule(min: 16, max: 255),
                FallbackResultClaimSpecialtyLengthRule(maxLength: 1000),
            ]
        )
    }
}
