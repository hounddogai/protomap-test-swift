import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched substitution digest must pass. Check returns its problems, or none.
    protocol BatchedSubstitutionDigestRule {
        func check(_ item: BatchedSubstitutionDigest) -> [String]
    }

    final class BatchedSubstitutionDigestTitleLengthRule: BatchedSubstitutionDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSubstitutionDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSubstitutionDigestRefillsRangeRule: BatchedSubstitutionDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSubstitutionDigest) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedSubstitutionDigestWindowDaysRangeRule: BatchedSubstitutionDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSubstitutionDigest) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched substitution digest.
    final class BatchedSubstitutionDigestValidator {
        var rules: [any BatchedSubstitutionDigestRule]

        init(rules: [any BatchedSubstitutionDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSubstitutionDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedSubstitutionDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSubstitutionDigest]) -> [String: [String]] {
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

    static func defaultBatchedSubstitutionDigestValidator() -> BatchedSubstitutionDigestValidator {
        return BatchedSubstitutionDigestValidator(
            rules: [
                BatchedSubstitutionDigestTitleLengthRule(maxLength: 16),
                BatchedSubstitutionDigestRefillsRangeRule(min: 80, max: 1000),
                BatchedSubstitutionDigestWindowDaysRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
