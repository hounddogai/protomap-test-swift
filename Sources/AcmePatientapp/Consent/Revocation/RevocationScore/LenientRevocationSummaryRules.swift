import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient revocation summary must pass. Check returns its problems, or none.
    protocol LenientRevocationSummaryRule {
        func check(_ item: LenientRevocationSummary) -> [String]
    }

    final class LenientRevocationSummaryRequiredProcedureCodeRule: LenientRevocationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRevocationSummary) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientRevocationSummaryRequiredLabelRule: LenientRevocationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRevocationSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientRevocationSummaryRequiredCodeRule: LenientRevocationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRevocationSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient revocation summary.
    final class LenientRevocationSummaryValidator {
        var rules: [any LenientRevocationSummaryRule]

        init(rules: [any LenientRevocationSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRevocationSummary) -> [String] {
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

        func requireValid(_ item: LenientRevocationSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRevocationSummary]) -> [String: [String]] {
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

    static func defaultLenientRevocationSummaryValidator() -> LenientRevocationSummaryValidator {
        return LenientRevocationSummaryValidator(
            rules: [
                LenientRevocationSummaryRequiredProcedureCodeRule(
                    message: "lenient revocation summary needs an entry"
                ),
                LenientRevocationSummaryRequiredLabelRule(message: "lenient revocation summary needs a value"),
                LenientRevocationSummaryRequiredCodeRule(message: "lenient revocation summary needs this field"),
            ]
        )
    }
}
