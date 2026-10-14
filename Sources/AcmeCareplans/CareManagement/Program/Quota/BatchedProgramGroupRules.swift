import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched program group must pass. Check returns its problems, or none.
    protocol BatchedProgramGroupRule {
        func check(_ item: BatchedProgramGroup) -> [String]
    }

    final class BatchedProgramGroupLabelLengthRule: BatchedProgramGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProgramGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedProgramGroupLimitRangeRule: BatchedProgramGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedProgramGroup) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedProgramGroupCodePrefixRule: BatchedProgramGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedProgramGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedProgramGroupCodeLengthRule: BatchedProgramGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProgramGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedProgramGroupRequiredCodeRule: BatchedProgramGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedProgramGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched program group.
    final class BatchedProgramGroupValidator {
        var rules: [any BatchedProgramGroupRule]

        init(rules: [any BatchedProgramGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedProgramGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedProgramGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedProgramGroup]) -> [String: [String]] {
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

    static func defaultBatchedProgramGroupValidator() -> BatchedProgramGroupValidator {
        return BatchedProgramGroupValidator(
            rules: [
                BatchedProgramGroupLabelLengthRule(maxLength: 32),
                BatchedProgramGroupLimitRangeRule(min: 1000, max: 3600),
                BatchedProgramGroupCodePrefixRule(prefix: "REF"),
                BatchedProgramGroupCodeLengthRule(maxLength: 80),
                BatchedProgramGroupRequiredCodeRule(message: "batched program group needs this field"),
            ]
        )
    }
}
