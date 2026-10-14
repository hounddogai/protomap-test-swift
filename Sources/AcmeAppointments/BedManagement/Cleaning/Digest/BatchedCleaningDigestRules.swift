import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched cleaning digest must pass. Check returns its problems, or none.
    protocol BatchedCleaningDigestRule {
        func check(_ item: BatchedCleaningDigest) -> [String]
    }

    final class BatchedCleaningDigestAllowedCodeRule: BatchedCleaningDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedCleaningDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class BatchedCleaningDigestDurationMinutesRangeRule: BatchedCleaningDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCleaningDigest) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedCleaningDigestCodePrefixRule: BatchedCleaningDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedCleaningDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched cleaning digest.
    final class BatchedCleaningDigestValidator {
        var rules: [any BatchedCleaningDigestRule]

        init(rules: [any BatchedCleaningDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCleaningDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedCleaningDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCleaningDigest]) -> [String: [String]] {
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

    static func defaultBatchedCleaningDigestValidator() -> BatchedCleaningDigestValidator {
        return BatchedCleaningDigestValidator(
            rules: [
                BatchedCleaningDigestAllowedCodeRule(allowed: []),
                BatchedCleaningDigestDurationMinutesRangeRule(min: 16, max: 255),
                BatchedCleaningDigestCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
