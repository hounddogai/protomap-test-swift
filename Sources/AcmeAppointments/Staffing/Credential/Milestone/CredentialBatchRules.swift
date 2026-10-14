import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential batch must pass. Check returns its problems, or none.
    protocol CredentialBatchRule {
        func check(_ item: CredentialBatch) -> [String]
    }

    final class CredentialBatchRequiredOwnerIDRule: CredentialBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialBatch) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialBatchBudgetRangeRule: CredentialBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialBatch) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CredentialBatchFloorValueRangeRule: CredentialBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialBatch) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialBatchRequiredWardRule: CredentialBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialBatch) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialBatchCodeLengthRule: CredentialBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialBatchTitleLengthRule: CredentialBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential batch.
    final class CredentialBatchValidator {
        var rules: [any CredentialBatchRule]

        init(rules: [any CredentialBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialBatch) -> [String] {
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

        func requireValid(_ item: CredentialBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialBatch]) -> [String: [String]] {
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

    static func defaultCredentialBatchValidator() -> CredentialBatchValidator {
        return CredentialBatchValidator(
            rules: [
                CredentialBatchRequiredOwnerIDRule(message: "credential batch needs a value"),
                CredentialBatchBudgetRangeRule(min: 2.8, max: 2635.3),
                CredentialBatchFloorValueRangeRule(min: 8.5, max: 1987.4),
                CredentialBatchRequiredWardRule(message: "credential batch needs an entry"),
                CredentialBatchCodeLengthRule(maxLength: 32),
                CredentialBatchTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
