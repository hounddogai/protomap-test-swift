import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance checkpoint must pass. Check returns its problems, or none.
    protocol RemittanceCheckpointRule {
        func check(_ item: RemittanceCheckpoint) -> [String]
    }

    final class RemittanceCheckpointStartsAtRangeRule: RemittanceCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceCheckpoint) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RemittanceCheckpointCategoryLengthRule: RemittanceCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceCheckpoint) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceCheckpointCodePrefixRule: RemittanceCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance checkpoint.
    final class RemittanceCheckpointValidator {
        var rules: [any RemittanceCheckpointRule]

        init(rules: [any RemittanceCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceCheckpoint) -> [String] {
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

        func requireValid(_ item: RemittanceCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceCheckpoint]) -> [String: [String]] {
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

    static func defaultRemittanceCheckpointValidator() -> RemittanceCheckpointValidator {
        return RemittanceCheckpointValidator(
            rules: [
                RemittanceCheckpointStartsAtRangeRule(min: 32, max: 3600),
                RemittanceCheckpointCategoryLengthRule(maxLength: 64),
                RemittanceCheckpointCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
