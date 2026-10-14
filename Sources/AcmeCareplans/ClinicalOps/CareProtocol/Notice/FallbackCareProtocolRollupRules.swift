import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback care protocol rollup must pass. Check returns its problems, or none.
    protocol FallbackCareProtocolRollupRule {
        func check(_ item: FallbackCareProtocolRollup) -> [String]
    }

    final class FallbackCareProtocolRollupCodePrefixRule: FallbackCareProtocolRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackCareProtocolRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolRollupRetriesRangeRule: FallbackCareProtocolRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCareProtocolRollup) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolRollupMinimumRangeRule: FallbackCareProtocolRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCareProtocolRollup) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackCareProtocolRollupTitleLengthRule: FallbackCareProtocolRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareProtocolRollup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolRollupRequiredTitleRule: FallbackCareProtocolRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCareProtocolRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback care protocol rollup.
    final class FallbackCareProtocolRollupValidator {
        var rules: [any FallbackCareProtocolRollupRule]

        init(rules: [any FallbackCareProtocolRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCareProtocolRollup) -> [String] {
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

        func requireValid(_ item: FallbackCareProtocolRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCareProtocolRollup]) -> [String: [String]] {
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

    static func defaultFallbackCareProtocolRollupValidator() -> FallbackCareProtocolRollupValidator {
        return FallbackCareProtocolRollupValidator(
            rules: [
                FallbackCareProtocolRollupCodePrefixRule(prefix: "Q"),
                FallbackCareProtocolRollupRetriesRangeRule(min: 80, max: 255),
                FallbackCareProtocolRollupMinimumRangeRule(min: 10.0, max: 3853.9),
                FallbackCareProtocolRollupTitleLengthRule(maxLength: 120),
                FallbackCareProtocolRollupRequiredTitleRule(message: "fallback care protocol rollup needs an entry"),
            ]
        )
    }
}
