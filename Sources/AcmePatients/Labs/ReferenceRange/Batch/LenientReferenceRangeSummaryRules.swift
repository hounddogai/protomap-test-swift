import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient reference range summary must pass. Check returns its problems, or none.
    protocol LenientReferenceRangeSummaryRule {
        func check(_ item: LenientReferenceRangeSummary) -> [String]
    }

    final class LenientReferenceRangeSummaryCodePrefixRule: LenientReferenceRangeSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientReferenceRangeSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientReferenceRangeSummaryRequiredClinicianIDRule: LenientReferenceRangeSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReferenceRangeSummary) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientReferenceRangeSummaryCeilingRangeRule: LenientReferenceRangeSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientReferenceRangeSummary) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient reference range summary.
    final class LenientReferenceRangeSummaryValidator {
        var rules: [any LenientReferenceRangeSummaryRule]

        init(rules: [any LenientReferenceRangeSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientReferenceRangeSummary) -> [String] {
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

        func requireValid(_ item: LenientReferenceRangeSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientReferenceRangeSummary]) -> [String: [String]] {
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

    static func defaultLenientReferenceRangeSummaryValidator() -> LenientReferenceRangeSummaryValidator {
        return LenientReferenceRangeSummaryValidator(
            rules: [
                LenientReferenceRangeSummaryCodePrefixRule(prefix: "X"),
                LenientReferenceRangeSummaryRequiredClinicianIDRule(
                    message: "lenient reference range summary needs an entry"
                ),
                LenientReferenceRangeSummaryCeilingRangeRule(min: 7.9, max: 983.8),
            ]
        )
    }
}
