import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched rounding mapping must pass. Check returns its problems, or none.
    protocol BatchedRoundingMappingRule {
        func check(_ item: BatchedRoundingMapping) -> [String]
    }

    final class BatchedRoundingMappingRequiredCodeRule: BatchedRoundingMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRoundingMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedRoundingMappingDescriptionLengthRule: BatchedRoundingMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedRoundingMapping) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedRoundingMappingNameLengthRule: BatchedRoundingMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedRoundingMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched rounding mapping.
    final class BatchedRoundingMappingValidator {
        var rules: [any BatchedRoundingMappingRule]

        init(rules: [any BatchedRoundingMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedRoundingMapping) -> [String] {
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

        func requireValid(_ item: BatchedRoundingMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedRoundingMapping]) -> [String: [String]] {
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

    static func defaultBatchedRoundingMappingValidator() -> BatchedRoundingMappingValidator {
        return BatchedRoundingMappingValidator(
            rules: [
                BatchedRoundingMappingRequiredCodeRule(message: "batched rounding mapping needs a value"),
                BatchedRoundingMappingDescriptionLengthRule(maxLength: 16),
                BatchedRoundingMappingNameLengthRule(maxLength: 255),
            ]
        )
    }
}
