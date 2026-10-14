import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range summary must pass. Check returns its problems, or none.
    protocol ReferenceRangeSummaryRule {
        func check(_ item: ReferenceRangeSummary) -> [String]
    }

    final class ReferenceRangeSummaryCodePrefixRule: ReferenceRangeSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferenceRangeSummaryClinicianIDLengthRule: ReferenceRangeSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeSummary) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeSummaryBudgetRangeRule: ReferenceRangeSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeSummary) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeSummaryCodeLengthRule: ReferenceRangeSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeSummaryRequiredSummaryRule: ReferenceRangeSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeSummary) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a reference range summary.
    final class ReferenceRangeSummaryValidator {
        var rules: [any ReferenceRangeSummaryRule]

        init(rules: [any ReferenceRangeSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeSummary]) -> [String: [String]] {
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

    static func defaultReferenceRangeSummaryValidator() -> ReferenceRangeSummaryValidator {
        return ReferenceRangeSummaryValidator(
            rules: [
                ReferenceRangeSummaryCodePrefixRule(prefix: "REF"),
                ReferenceRangeSummaryClinicianIDLengthRule(maxLength: 1000),
                ReferenceRangeSummaryBudgetRangeRule(min: 5.9, max: 1425.1),
                ReferenceRangeSummaryCodeLengthRule(maxLength: 1000),
                ReferenceRangeSummaryRequiredSummaryRule(message: "reference range summary needs this field"),
            ]
        )
    }
}
