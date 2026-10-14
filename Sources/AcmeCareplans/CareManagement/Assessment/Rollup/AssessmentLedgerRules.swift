import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment ledger must pass. Check returns its problems, or none.
    protocol AssessmentLedgerRule {
        func check(_ item: AssessmentLedger) -> [String]
    }

    final class AssessmentLedgerWeightRangeRule: AssessmentLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentLedger) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AssessmentLedgerCodeLengthRule: AssessmentLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentLedgerRequiredUnitRule: AssessmentLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentLedger) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentLedgerRequiredNameRule: AssessmentLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a assessment ledger.
    final class AssessmentLedgerValidator {
        var rules: [any AssessmentLedgerRule]

        init(rules: [any AssessmentLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentLedger]) -> [String: [String]] {
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

    static func defaultAssessmentLedgerValidator() -> AssessmentLedgerValidator {
        return AssessmentLedgerValidator(
            rules: [
                AssessmentLedgerWeightRangeRule(min: 9.7, max: 4400.4),
                AssessmentLedgerCodeLengthRule(maxLength: 3600),
                AssessmentLedgerRequiredUnitRule(message: "assessment ledger needs a value"),
                AssessmentLedgerRequiredNameRule(message: "assessment ledger needs an entry"),
            ]
        )
    }
}
