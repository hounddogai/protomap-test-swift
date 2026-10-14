import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score request must pass. Check returns its problems, or none.
    protocol RiskScoreRequestRule {
        func check(_ item: RiskScoreRequest) -> [String]
    }

    final class RiskScoreRequestEncounterIDLengthRule: RiskScoreRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreRequest) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreRequestRequiredAllergyRule: RiskScoreRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreRequest) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreRequestRequiredTitleRule: RiskScoreRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreRequestUpdatedAtRangeRule: RiskScoreRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreRequest) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score request.
    final class RiskScoreRequestValidator {
        var rules: [any RiskScoreRequestRule]

        init(rules: [any RiskScoreRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreRequest]) -> [String: [String]] {
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

    static func defaultRiskScoreRequestValidator() -> RiskScoreRequestValidator {
        return RiskScoreRequestValidator(
            rules: [
                RiskScoreRequestEncounterIDLengthRule(maxLength: 32),
                RiskScoreRequestRequiredAllergyRule(message: "risk score request needs a value"),
                RiskScoreRequestRequiredTitleRule(message: "risk score request needs a value"),
                RiskScoreRequestUpdatedAtRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
