import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched disclosure tier must pass. Check returns its problems, or none.
    protocol BatchedDisclosureTierRule {
        func check(_ item: BatchedDisclosureTier) -> [String]
    }

    final class BatchedDisclosureTierRequiredSourceRule: BatchedDisclosureTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDisclosureTier) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDisclosureTierTitleLengthRule: BatchedDisclosureTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDisclosureTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDisclosureTierCodePrefixRule: BatchedDisclosureTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedDisclosureTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedDisclosureTierAllowedSourceRule: BatchedDisclosureTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedDisclosureTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is blocked"]
            }
            return []
        }
    }

    final class BatchedDisclosureTierAmountRangeRule: BatchedDisclosureTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDisclosureTier) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedDisclosureTierRevisionRangeRule: BatchedDisclosureTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDisclosureTier) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched disclosure tier.
    final class BatchedDisclosureTierValidator {
        var rules: [any BatchedDisclosureTierRule]

        init(rules: [any BatchedDisclosureTierRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDisclosureTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedDisclosureTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDisclosureTier]) -> [String: [String]] {
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

    static func defaultBatchedDisclosureTierValidator() -> BatchedDisclosureTierValidator {
        return BatchedDisclosureTierValidator(
            rules: [
                BatchedDisclosureTierRequiredSourceRule(message: "batched disclosure tier needs an entry"),
                BatchedDisclosureTierTitleLengthRule(maxLength: 64),
                BatchedDisclosureTierCodePrefixRule(prefix: "REF"),
                BatchedDisclosureTierAllowedSourceRule(allowed: ["regional", "strict", "lenient"]),
                BatchedDisclosureTierAmountRangeRule(min: 5.6, max: 120.5),
                BatchedDisclosureTierRevisionRangeRule(min: 64, max: 3600),
            ]
        )
    }
}
