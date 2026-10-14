import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling rounding digest must pass. Check returns its problems, or none.
    protocol RollingRoundingDigestRule {
        func check(_ item: RollingRoundingDigest) -> [String]
    }

    final class RollingRoundingDigestCodePrefixRule: RollingRoundingDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingRoundingDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingRoundingDigestNameLengthRule: RollingRoundingDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRoundingDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingRoundingDigestAttemptsRangeRule: RollingRoundingDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingRoundingDigest) -> [String] {
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

    /// Runs every rule of a rolling rounding digest.
    final class RollingRoundingDigestValidator {
        var rules: [any RollingRoundingDigestRule]

        init(rules: [any RollingRoundingDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRoundingDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingRoundingDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRoundingDigest]) -> [String: [String]] {
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

    static func defaultRollingRoundingDigestValidator() -> RollingRoundingDigestValidator {
        return RollingRoundingDigestValidator(
            rules: [
                RollingRoundingDigestCodePrefixRule(prefix: "OPS"),
                RollingRoundingDigestNameLengthRule(maxLength: 1000),
                RollingRoundingDigestAttemptsRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
