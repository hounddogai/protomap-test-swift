import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional revocation batch must pass. Check returns its problems, or none.
    protocol RegionalRevocationBatchRule {
        func check(_ item: RegionalRevocationBatch) -> [String]
    }

    final class RegionalRevocationBatchRequiredCodeRule: RegionalRevocationBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRevocationBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalRevocationBatchRequiredTitleRule: RegionalRevocationBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRevocationBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalRevocationBatchVisitMinutesRangeRule: RegionalRevocationBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRevocationBatch) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalRevocationBatchRequiredAllergyRule: RegionalRevocationBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRevocationBatch) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalRevocationBatchAllergyLengthRule: RegionalRevocationBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRevocationBatch) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalRevocationBatchCodeLengthRule: RegionalRevocationBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRevocationBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional revocation batch.
    final class RegionalRevocationBatchValidator {
        var rules: [any RegionalRevocationBatchRule]

        init(rules: [any RegionalRevocationBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRevocationBatch) -> [String] {
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

        func requireValid(_ item: RegionalRevocationBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRevocationBatch]) -> [String: [String]] {
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

    static func defaultRegionalRevocationBatchValidator() -> RegionalRevocationBatchValidator {
        return RegionalRevocationBatchValidator(
            rules: [
                RegionalRevocationBatchRequiredCodeRule(message: "regional revocation batch needs this field"),
                RegionalRevocationBatchRequiredTitleRule(message: "regional revocation batch needs a value"),
                RegionalRevocationBatchVisitMinutesRangeRule(min: 64, max: 3600),
                RegionalRevocationBatchRequiredAllergyRule(message: "regional revocation batch needs a value"),
                RegionalRevocationBatchAllergyLengthRule(maxLength: 120),
                RegionalRevocationBatchCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
