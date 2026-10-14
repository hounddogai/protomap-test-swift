import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback follow up baseline must pass. Check returns its problems, or none.
    protocol FallbackFollowUpBaselineRule {
        func check(_ item: FallbackFollowUpBaseline) -> [String]
    }

    final class FallbackFollowUpBaselineCodeLengthRule: FallbackFollowUpBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackFollowUpBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackFollowUpBaselineBatchSizeRangeRule: FallbackFollowUpBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackFollowUpBaseline) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackFollowUpBaselineCodePrefixRule: FallbackFollowUpBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackFollowUpBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackFollowUpBaselineCreatedAtRangeRule: FallbackFollowUpBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackFollowUpBaseline) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback follow up baseline.
    final class FallbackFollowUpBaselineValidator {
        var rules: [any FallbackFollowUpBaselineRule]

        init(rules: [any FallbackFollowUpBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackFollowUpBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackFollowUpBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackFollowUpBaseline]) -> [String: [String]] {
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

    static func defaultFallbackFollowUpBaselineValidator() -> FallbackFollowUpBaselineValidator {
        return FallbackFollowUpBaselineValidator(
            rules: [
                FallbackFollowUpBaselineCodeLengthRule(maxLength: 1000),
                FallbackFollowUpBaselineBatchSizeRangeRule(min: 80, max: 120),
                FallbackFollowUpBaselineCodePrefixRule(prefix: "ACM"),
                FallbackFollowUpBaselineCreatedAtRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
