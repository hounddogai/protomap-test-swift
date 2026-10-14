import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary claim digest must pass. Check returns its problems, or none.
    protocol PrimaryClaimDigestRule {
        func check(_ item: PrimaryClaimDigest) -> [String]
    }

    final class PrimaryClaimDigestThresholdRangeRule: PrimaryClaimDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryClaimDigest) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryClaimDigestTitleLengthRule: PrimaryClaimDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryClaimDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryClaimDigestRequiredTitleRule: PrimaryClaimDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryClaimDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryClaimDigestCreatedAtRangeRule: PrimaryClaimDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryClaimDigest) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary claim digest.
    final class PrimaryClaimDigestValidator {
        var rules: [any PrimaryClaimDigestRule]

        init(rules: [any PrimaryClaimDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryClaimDigest) -> [String] {
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

        func requireValid(_ item: PrimaryClaimDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryClaimDigest]) -> [String: [String]] {
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

    static func defaultPrimaryClaimDigestValidator() -> PrimaryClaimDigestValidator {
        return PrimaryClaimDigestValidator(
            rules: [
                PrimaryClaimDigestThresholdRangeRule(min: 6.7, max: 3563.7),
                PrimaryClaimDigestTitleLengthRule(maxLength: 3600),
                PrimaryClaimDigestRequiredTitleRule(message: "primary claim digest needs a value"),
                PrimaryClaimDigestCreatedAtRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
