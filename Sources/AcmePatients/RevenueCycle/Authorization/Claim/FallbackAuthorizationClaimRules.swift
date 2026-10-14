import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback authorization claim must pass. Check returns its problems, or none.
    protocol FallbackAuthorizationClaimRule {
        func check(_ item: FallbackAuthorizationClaim) -> [String]
    }

    final class FallbackAuthorizationClaimFloorValueRangeRule: FallbackAuthorizationClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackAuthorizationClaim) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackAuthorizationClaimCodePrefixRule: FallbackAuthorizationClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackAuthorizationClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackAuthorizationClaimTitleLengthRule: FallbackAuthorizationClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAuthorizationClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAuthorizationClaimRequiredTitleRule: FallbackAuthorizationClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAuthorizationClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAuthorizationClaimRequiredCodeRule: FallbackAuthorizationClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAuthorizationClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback authorization claim.
    final class FallbackAuthorizationClaimValidator {
        var rules: [any FallbackAuthorizationClaimRule]

        init(rules: [any FallbackAuthorizationClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackAuthorizationClaim) -> [String] {
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

        func requireValid(_ item: FallbackAuthorizationClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackAuthorizationClaim]) -> [String: [String]] {
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

    static func defaultFallbackAuthorizationClaimValidator() -> FallbackAuthorizationClaimValidator {
        return FallbackAuthorizationClaimValidator(
            rules: [
                FallbackAuthorizationClaimFloorValueRangeRule(min: 2.6, max: 205.3),
                FallbackAuthorizationClaimCodePrefixRule(prefix: "X"),
                FallbackAuthorizationClaimTitleLengthRule(maxLength: 1000),
                FallbackAuthorizationClaimRequiredTitleRule(message: "fallback authorization claim needs a value"),
                FallbackAuthorizationClaimRequiredCodeRule(message: "fallback authorization claim needs an entry"),
            ]
        )
    }
}
