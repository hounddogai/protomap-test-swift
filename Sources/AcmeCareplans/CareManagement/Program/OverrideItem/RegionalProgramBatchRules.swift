import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional program batch must pass. Check returns its problems, or none.
    protocol RegionalProgramBatchRule {
        func check(_ item: RegionalProgramBatch) -> [String]
    }

    final class RegionalProgramBatchRequiredLabelRule: RegionalProgramBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalProgramBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalProgramBatchContactEmailLengthRule: RegionalProgramBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalProgramBatch) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalProgramBatchPinnedGuardRule: RegionalProgramBatchRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RegionalProgramBatch) -> [String] {
            if item.pinned && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class RegionalProgramBatchRequiredSummaryRule: RegionalProgramBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalProgramBatch) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional program batch.
    final class RegionalProgramBatchValidator {
        var rules: [any RegionalProgramBatchRule]

        init(rules: [any RegionalProgramBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalProgramBatch) -> [String] {
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

        func requireValid(_ item: RegionalProgramBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalProgramBatch]) -> [String: [String]] {
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

    static func defaultRegionalProgramBatchValidator() -> RegionalProgramBatchValidator {
        return RegionalProgramBatchValidator(
            rules: [
                RegionalProgramBatchRequiredLabelRule(message: "regional program batch needs an entry"),
                RegionalProgramBatchContactEmailLengthRule(maxLength: 255),
                RegionalProgramBatchPinnedGuardRule(limit: 5.5),
                RegionalProgramBatchRequiredSummaryRule(message: "regional program batch needs an entry"),
            ]
        )
    }
}
