import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement draft must pass. Check returns its problems, or none.
    protocol StatementDraftRule {
        func check(_ item: StatementDraft) -> [String]
    }

    final class StatementDraftDosageMgRangeRule: StatementDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementDraft) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementDraftRequiredPatientRefRule: StatementDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementDraft) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementDraftRequiredNameRule: StatementDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementDraftFloorValueRangeRule: StatementDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementDraft) -> [String] {
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

    /// Runs every rule of a statement draft.
    final class StatementDraftValidator {
        var rules: [any StatementDraftRule]

        init(rules: [any StatementDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementDraft]) -> [String: [String]] {
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

    static func defaultStatementDraftValidator() -> StatementDraftValidator {
        return StatementDraftValidator(
            rules: [
                StatementDraftDosageMgRangeRule(min: 7.7, max: 4130.0),
                StatementDraftRequiredPatientRefRule(message: "statement draft needs a value"),
                StatementDraftRequiredNameRule(message: "statement draft needs an entry"),
                StatementDraftFloorValueRangeRule(min: 8.7, max: 1642.8),
            ]
        )
    }
}
