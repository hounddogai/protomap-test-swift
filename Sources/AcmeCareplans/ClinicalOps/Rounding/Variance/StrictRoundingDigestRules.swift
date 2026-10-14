import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict rounding digest must pass. Check returns its problems, or none.
    protocol StrictRoundingDigestRule {
        func check(_ item: StrictRoundingDigest) -> [String]
    }

    final class StrictRoundingDigestSourceLengthRule: StrictRoundingDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRoundingDigest) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictRoundingDigestTitleLengthRule: StrictRoundingDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRoundingDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictRoundingDigestThresholdRangeRule: StrictRoundingDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictRoundingDigest) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict rounding digest.
    final class StrictRoundingDigestValidator {
        var rules: [any StrictRoundingDigestRule]

        init(rules: [any StrictRoundingDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictRoundingDigest) -> [String] {
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

        func requireValid(_ item: StrictRoundingDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictRoundingDigest]) -> [String: [String]] {
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

    static func defaultStrictRoundingDigestValidator() -> StrictRoundingDigestValidator {
        return StrictRoundingDigestValidator(
            rules: [
                StrictRoundingDigestSourceLengthRule(maxLength: 3600),
                StrictRoundingDigestTitleLengthRule(maxLength: 86400),
                StrictRoundingDigestThresholdRangeRule(min: 1.8, max: 1439.3),
            ]
        )
    }
}
