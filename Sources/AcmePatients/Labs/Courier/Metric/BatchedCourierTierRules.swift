import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched courier tier must pass. Check returns its problems, or none.
    protocol BatchedCourierTierRule {
        func check(_ item: BatchedCourierTier) -> [String]
    }

    final class BatchedCourierTierLabelLengthRule: BatchedCourierTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCourierTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCourierTierCodePrefixRule: BatchedCourierTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedCourierTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedCourierTierCountryLengthRule: BatchedCourierTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCourierTier) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCourierTierEncounterIDLengthRule: BatchedCourierTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCourierTier) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched courier tier.
    final class BatchedCourierTierValidator {
        var rules: [any BatchedCourierTierRule]

        init(rules: [any BatchedCourierTierRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCourierTier) -> [String] {
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

        func requireValid(_ item: BatchedCourierTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCourierTier]) -> [String: [String]] {
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

    static func defaultBatchedCourierTierValidator() -> BatchedCourierTierValidator {
        return BatchedCourierTierValidator(
            rules: [
                BatchedCourierTierLabelLengthRule(maxLength: 120),
                BatchedCourierTierCodePrefixRule(prefix: "REF"),
                BatchedCourierTierCountryLengthRule(maxLength: 64),
                BatchedCourierTierEncounterIDLengthRule(maxLength: 86400),
            ]
        )
    }
}
