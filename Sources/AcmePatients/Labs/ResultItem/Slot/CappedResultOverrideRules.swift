import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped result override must pass. Check returns its problems, or none.
    protocol CappedResultOverrideRule {
        func check(_ item: CappedResultOverride) -> [String]
    }

    final class CappedResultOverrideBatchSizeRangeRule: CappedResultOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedResultOverride) -> [String] {
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

    final class CappedResultOverrideCodePrefixRule: CappedResultOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedResultOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedResultOverrideCodeLengthRule: CappedResultOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedResultOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedResultOverrideNameLengthRule: CappedResultOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedResultOverride) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped result override.
    final class CappedResultOverrideValidator {
        var rules: [any CappedResultOverrideRule]

        init(rules: [any CappedResultOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedResultOverride) -> [String] {
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

        func requireValid(_ item: CappedResultOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedResultOverride]) -> [String: [String]] {
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

    static func defaultCappedResultOverrideValidator() -> CappedResultOverrideValidator {
        return CappedResultOverrideValidator(
            rules: [
                CappedResultOverrideBatchSizeRangeRule(min: 1000, max: 86400),
                CappedResultOverrideCodePrefixRule(prefix: "Q"),
                CappedResultOverrideCodeLengthRule(maxLength: 80),
                CappedResultOverrideNameLengthRule(maxLength: 16),
            ]
        )
    }
}
