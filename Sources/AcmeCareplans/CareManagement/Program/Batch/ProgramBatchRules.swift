import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program batch must pass. Check returns its problems, or none.
    protocol ProgramBatchRule {
        func check(_ item: ProgramBatch) -> [String]
    }

    final class ProgramBatchRequiredCodeRule: ProgramBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramBatchLabelLengthRule: ProgramBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramBatch) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramBatchCodePrefixRule: ProgramBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProgramBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProgramBatchRegionLengthRule: ProgramBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramBatch) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramBatchThresholdRangeRule: ProgramBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramBatch) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a program batch.
    final class ProgramBatchValidator {
        var rules: [any ProgramBatchRule]

        init(rules: [any ProgramBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramBatch) -> [String] {
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

        func requireValid(_ item: ProgramBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramBatch]) -> [String: [String]] {
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

    static func defaultProgramBatchValidator() -> ProgramBatchValidator {
        return ProgramBatchValidator(
            rules: [
                ProgramBatchRequiredCodeRule(message: "program batch needs an entry"),
                ProgramBatchLabelLengthRule(maxLength: 1000),
                ProgramBatchCodePrefixRule(prefix: "X"),
                ProgramBatchRegionLengthRule(maxLength: 80),
                ProgramBatchThresholdRangeRule(min: 3.8, max: 3601.0),
            ]
        )
    }
}
