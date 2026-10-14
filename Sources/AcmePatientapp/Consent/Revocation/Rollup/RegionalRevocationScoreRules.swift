import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional revocation score must pass. Check returns its problems, or none.
    protocol RegionalRevocationScoreRule {
        func check(_ item: RegionalRevocationScore) -> [String]
    }

    final class RegionalRevocationScoreAmountRangeRule: RegionalRevocationScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRevocationScore) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalRevocationScoreRequiredCountryRule: RegionalRevocationScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRevocationScore) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalRevocationScorePatientRefLengthRule: RegionalRevocationScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRevocationScore) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalRevocationScoreLabelLengthRule: RegionalRevocationScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRevocationScore) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalRevocationScoreRequiredCodeRule: RegionalRevocationScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRevocationScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalRevocationScoreSequenceRangeRule: RegionalRevocationScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRevocationScore) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional revocation score.
    final class RegionalRevocationScoreValidator {
        var rules: [any RegionalRevocationScoreRule]

        init(rules: [any RegionalRevocationScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRevocationScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalRevocationScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRevocationScore]) -> [String: [String]] {
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

    static func defaultRegionalRevocationScoreValidator() -> RegionalRevocationScoreValidator {
        return RegionalRevocationScoreValidator(
            rules: [
                RegionalRevocationScoreAmountRangeRule(min: 9.8, max: 4234.6),
                RegionalRevocationScoreRequiredCountryRule(message: "regional revocation score needs a value"),
                RegionalRevocationScorePatientRefLengthRule(maxLength: 120),
                RegionalRevocationScoreLabelLengthRule(maxLength: 255),
                RegionalRevocationScoreRequiredCodeRule(message: "regional revocation score needs this field"),
                RegionalRevocationScoreSequenceRangeRule(min: 64, max: 1000),
            ]
        )
    }
}
