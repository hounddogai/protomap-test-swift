import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient consent form batch must pass. Check returns its problems, or none.
    protocol LenientConsentFormBatchRule {
        func check(_ item: LenientConsentFormBatch) -> [String]
    }

    final class LenientConsentFormBatchAllowedProcedureCodeRule: LenientConsentFormBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientConsentFormBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is missing"]
            }
            return []
        }
    }

    final class LenientConsentFormBatchCapacityRangeRule: LenientConsentFormBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientConsentFormBatch) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientConsentFormBatchRequiredNotesRule: LenientConsentFormBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientConsentFormBatch) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientConsentFormBatchProcedureCodeLengthRule: LenientConsentFormBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientConsentFormBatch) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientConsentFormBatchTitleLengthRule: LenientConsentFormBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientConsentFormBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient consent form batch.
    final class LenientConsentFormBatchValidator {
        var rules: [any LenientConsentFormBatchRule]

        init(rules: [any LenientConsentFormBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientConsentFormBatch) -> [String] {
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

        func requireValid(_ item: LenientConsentFormBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientConsentFormBatch]) -> [String: [String]] {
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

    static func defaultLenientConsentFormBatchValidator() -> LenientConsentFormBatchValidator {
        return LenientConsentFormBatchValidator(
            rules: [
                LenientConsentFormBatchAllowedProcedureCodeRule(allowed: []),
                LenientConsentFormBatchCapacityRangeRule(min: 120, max: 1000),
                LenientConsentFormBatchRequiredNotesRule(message: "lenient consent form batch needs a value"),
                LenientConsentFormBatchProcedureCodeLengthRule(maxLength: 64),
                LenientConsentFormBatchTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
