import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a batched modality mapping must pass. Check returns its problems, or none.
    protocol BatchedModalityMappingRule {
        func check(_ item: BatchedModalityMapping) -> [String]
    }

    final class BatchedModalityMappingRequiredNameRule: BatchedModalityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedModalityMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedModalityMappingRequiredPatientRefRule: BatchedModalityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedModalityMapping) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedModalityMappingVisitMinutesRangeRule: BatchedModalityMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedModalityMapping) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedModalityMappingRequiredEncounterIDRule: BatchedModalityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedModalityMapping) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedModalityMappingCodeLengthRule: BatchedModalityMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedModalityMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched modality mapping.
    final class BatchedModalityMappingValidator {
        var rules: [any BatchedModalityMappingRule]

        init(rules: [any BatchedModalityMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedModalityMapping) -> [String] {
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

        func requireValid(_ item: BatchedModalityMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedModalityMapping]) -> [String: [String]] {
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

    static func defaultBatchedModalityMappingValidator() -> BatchedModalityMappingValidator {
        return BatchedModalityMappingValidator(
            rules: [
                BatchedModalityMappingRequiredNameRule(message: "batched modality mapping needs this field"),
                BatchedModalityMappingRequiredPatientRefRule(message: "batched modality mapping needs this field"),
                BatchedModalityMappingVisitMinutesRangeRule(min: 32, max: 64),
                BatchedModalityMappingRequiredEncounterIDRule(message: "batched modality mapping needs a value"),
                BatchedModalityMappingCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
