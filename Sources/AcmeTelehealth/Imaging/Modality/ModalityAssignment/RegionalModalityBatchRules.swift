import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional modality batch must pass. Check returns its problems, or none.
    protocol RegionalModalityBatchRule {
        func check(_ item: RegionalModalityBatch) -> [String]
    }

    final class RegionalModalityBatchRequiredLabelRule: RegionalModalityBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalModalityBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalModalityBatchRequiredNameRule: RegionalModalityBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalModalityBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalModalityBatchCodeLengthRule: RegionalModalityBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalModalityBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional modality batch.
    final class RegionalModalityBatchValidator {
        var rules: [any RegionalModalityBatchRule]

        init(rules: [any RegionalModalityBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalModalityBatch) -> [String] {
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

        func requireValid(_ item: RegionalModalityBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalModalityBatch]) -> [String: [String]] {
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

    static func defaultRegionalModalityBatchValidator() -> RegionalModalityBatchValidator {
        return RegionalModalityBatchValidator(
            rules: [
                RegionalModalityBatchRequiredLabelRule(message: "regional modality batch needs a value"),
                RegionalModalityBatchRequiredNameRule(message: "regional modality batch needs an entry"),
                RegionalModalityBatchCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
