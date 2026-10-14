import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback program batch must pass. Check returns its problems, or none.
    protocol FallbackProgramBatchRule {
        func check(_ item: FallbackProgramBatch) -> [String]
    }

    final class FallbackProgramBatchGraceDaysRangeRule: FallbackProgramBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackProgramBatch) -> [String] {
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

    final class FallbackProgramBatchRequiredCodeRule: FallbackProgramBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackProgramBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackProgramBatchCodePrefixRule: FallbackProgramBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackProgramBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackProgramBatchLabelLengthRule: FallbackProgramBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackProgramBatch) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackProgramBatchRatioRangeRule: FallbackProgramBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackProgramBatch) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackProgramBatchCodeLengthRule: FallbackProgramBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackProgramBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback program batch.
    final class FallbackProgramBatchValidator {
        var rules: [any FallbackProgramBatchRule]

        init(rules: [any FallbackProgramBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackProgramBatch) -> [String] {
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

        func requireValid(_ item: FallbackProgramBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackProgramBatch]) -> [String: [String]] {
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

    static func defaultFallbackProgramBatchValidator() -> FallbackProgramBatchValidator {
        return FallbackProgramBatchValidator(
            rules: [
                FallbackProgramBatchGraceDaysRangeRule(min: 32, max: 32),
                FallbackProgramBatchRequiredCodeRule(message: "fallback program batch needs this field"),
                FallbackProgramBatchCodePrefixRule(prefix: "X"),
                FallbackProgramBatchLabelLengthRule(maxLength: 3600),
                FallbackProgramBatchRatioRangeRule(min: 4.1, max: 1802.0),
                FallbackProgramBatchCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
