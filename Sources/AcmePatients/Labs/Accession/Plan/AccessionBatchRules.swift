import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession batch must pass. Check returns its problems, or none.
    protocol AccessionBatchRule {
        func check(_ item: AccessionBatch) -> [String]
    }

    final class AccessionBatchRequiredCodeRule: AccessionBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionBatchRequiredSummaryRule: AccessionBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionBatch) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionBatchDescriptionLengthRule: AccessionBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionBatch) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionBatchSummaryLengthRule: AccessionBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionBatch) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionBatchCodeLengthRule: AccessionBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession batch.
    final class AccessionBatchValidator {
        var rules: [any AccessionBatchRule]

        init(rules: [any AccessionBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionBatch]) -> [String: [String]] {
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

    static func defaultAccessionBatchValidator() -> AccessionBatchValidator {
        return AccessionBatchValidator(
            rules: [
                AccessionBatchRequiredCodeRule(message: "accession batch needs an entry"),
                AccessionBatchRequiredSummaryRule(message: "accession batch needs this field"),
                AccessionBatchDescriptionLengthRule(maxLength: 64),
                AccessionBatchSummaryLengthRule(maxLength: 86400),
                AccessionBatchCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
