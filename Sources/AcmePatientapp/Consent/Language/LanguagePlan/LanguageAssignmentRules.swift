import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language assignment must pass. Check returns its problems, or none.
    protocol LanguageAssignmentRule {
        func check(_ item: LanguageAssignment) -> [String]
    }

    final class LanguageAssignmentAmountRangeRule: LanguageAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageAssignment) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguageAssignmentRequiredCodeRule: LanguageAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageAssignmentRequiredDiagnosisCodeRule: LanguageAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageAssignment) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageAssignmentCostRangeRule: LanguageAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageAssignment) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a language assignment.
    final class LanguageAssignmentValidator {
        var rules: [any LanguageAssignmentRule]

        init(rules: [any LanguageAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageAssignment]) -> [String: [String]] {
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

    static func defaultLanguageAssignmentValidator() -> LanguageAssignmentValidator {
        return LanguageAssignmentValidator(
            rules: [
                LanguageAssignmentAmountRangeRule(min: 2.3, max: 1649.8),
                LanguageAssignmentRequiredCodeRule(message: "language assignment needs an entry"),
                LanguageAssignmentRequiredDiagnosisCodeRule(message: "language assignment needs an entry"),
                LanguageAssignmentCostRangeRule(min: 7.0, max: 3542.7),
            ]
        )
    }
}
