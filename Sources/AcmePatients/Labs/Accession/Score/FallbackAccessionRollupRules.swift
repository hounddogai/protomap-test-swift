import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback accession rollup must pass. Check returns its problems, or none.
    protocol FallbackAccessionRollupRule {
        func check(_ item: FallbackAccessionRollup) -> [String]
    }

    final class FallbackAccessionRollupExternalRefLengthRule: FallbackAccessionRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAccessionRollup) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAccessionRollupTitleLengthRule: FallbackAccessionRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAccessionRollup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAccessionRollupGraceDaysRangeRule: FallbackAccessionRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackAccessionRollup) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackAccessionRollupCodePrefixRule: FallbackAccessionRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackAccessionRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackAccessionRollupRequiredTitleRule: FallbackAccessionRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAccessionRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAccessionRollupRequiredChecksumRule: FallbackAccessionRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAccessionRollup) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback accession rollup.
    final class FallbackAccessionRollupValidator {
        var rules: [any FallbackAccessionRollupRule]

        init(rules: [any FallbackAccessionRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackAccessionRollup) -> [String] {
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

        func requireValid(_ item: FallbackAccessionRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackAccessionRollup]) -> [String: [String]] {
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

    static func defaultFallbackAccessionRollupValidator() -> FallbackAccessionRollupValidator {
        return FallbackAccessionRollupValidator(
            rules: [
                FallbackAccessionRollupExternalRefLengthRule(maxLength: 1000),
                FallbackAccessionRollupTitleLengthRule(maxLength: 120),
                FallbackAccessionRollupGraceDaysRangeRule(min: 64, max: 1000),
                FallbackAccessionRollupCodePrefixRule(prefix: "REF"),
                FallbackAccessionRollupRequiredTitleRule(message: "fallback accession rollup needs a value"),
                FallbackAccessionRollupRequiredChecksumRule(message: "fallback accession rollup needs an entry"),
            ]
        )
    }
}
