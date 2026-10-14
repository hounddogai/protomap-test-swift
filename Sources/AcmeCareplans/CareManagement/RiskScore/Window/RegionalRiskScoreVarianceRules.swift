import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional risk score variance must pass. Check returns its problems, or none.
    protocol RegionalRiskScoreVarianceRule {
        func check(_ item: RegionalRiskScoreVariance) -> [String]
    }

    final class RegionalRiskScoreVarianceContactEmailLengthRule: RegionalRiskScoreVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRiskScoreVariance) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalRiskScoreVarianceRequiredTitleRule: RegionalRiskScoreVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRiskScoreVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalRiskScoreVarianceFacilityLengthRule: RegionalRiskScoreVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRiskScoreVariance) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalRiskScoreVarianceRequiredFacilityRule: RegionalRiskScoreVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRiskScoreVariance) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional risk score variance.
    final class RegionalRiskScoreVarianceValidator {
        var rules: [any RegionalRiskScoreVarianceRule]

        init(rules: [any RegionalRiskScoreVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRiskScoreVariance) -> [String] {
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

        func requireValid(_ item: RegionalRiskScoreVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRiskScoreVariance]) -> [String: [String]] {
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

    static func defaultRegionalRiskScoreVarianceValidator() -> RegionalRiskScoreVarianceValidator {
        return RegionalRiskScoreVarianceValidator(
            rules: [
                RegionalRiskScoreVarianceContactEmailLengthRule(maxLength: 64),
                RegionalRiskScoreVarianceRequiredTitleRule(message: "regional risk score variance needs a value"),
                RegionalRiskScoreVarianceFacilityLengthRule(maxLength: 80),
                RegionalRiskScoreVarianceRequiredFacilityRule(message: "regional risk score variance needs an entry"),
            ]
        )
    }
}
