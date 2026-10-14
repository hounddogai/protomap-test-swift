import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a strict risk score request must pass. Check returns its problems, or none.
    protocol StrictRiskScoreRequestRule {
        func check(_ item: StrictRiskScoreRequest) -> [String]
    }

    final class StrictRiskScoreRequestCodeLengthRule: StrictRiskScoreRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRiskScoreRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictRiskScoreRequestPatientRefLengthRule: StrictRiskScoreRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRiskScoreRequest) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictRiskScoreRequestRequiredPatientRefRule: StrictRiskScoreRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictRiskScoreRequest) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictRiskScoreRequestNotesLengthRule: StrictRiskScoreRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRiskScoreRequest) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictRiskScoreRequestCeilingRangeRule: StrictRiskScoreRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictRiskScoreRequest) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict risk score request.
    final class StrictRiskScoreRequestValidator {
        var rules: [any StrictRiskScoreRequestRule]

        init(rules: [any StrictRiskScoreRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictRiskScoreRequest) -> [String] {
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

        func requireValid(_ item: StrictRiskScoreRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictRiskScoreRequest]) -> [String: [String]] {
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

    static func defaultStrictRiskScoreRequestValidator() -> StrictRiskScoreRequestValidator {
        return StrictRiskScoreRequestValidator(
            rules: [
                StrictRiskScoreRequestCodeLengthRule(maxLength: 1000),
                StrictRiskScoreRequestPatientRefLengthRule(maxLength: 120),
                StrictRiskScoreRequestRequiredPatientRefRule(message: "strict risk score request needs an entry"),
                StrictRiskScoreRequestNotesLengthRule(maxLength: 86400),
                StrictRiskScoreRequestCeilingRangeRule(min: 6.8, max: 3955.1),
            ]
        )
    }
}
