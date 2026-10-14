import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a weighted credential variance must pass. Check returns its problems, or none.
    protocol WeightedCredentialVarianceRule {
        func check(_ item: WeightedCredentialVariance) -> [String]
    }

    final class WeightedCredentialVarianceRequiredEncounterIDRule: WeightedCredentialVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCredentialVariance) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCredentialVarianceFloorValueRangeRule: WeightedCredentialVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCredentialVariance) -> [String] {
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

    final class WeightedCredentialVarianceLabelLengthRule: WeightedCredentialVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCredentialVariance) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted credential variance.
    final class WeightedCredentialVarianceValidator {
        var rules: [any WeightedCredentialVarianceRule]

        init(rules: [any WeightedCredentialVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCredentialVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedCredentialVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCredentialVariance]) -> [String: [String]] {
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

    static func defaultWeightedCredentialVarianceValidator() -> WeightedCredentialVarianceValidator {
        return WeightedCredentialVarianceValidator(
            rules: [
                WeightedCredentialVarianceRequiredEncounterIDRule(
                    message: "weighted credential variance needs a value"
                ),
                WeightedCredentialVarianceFloorValueRangeRule(min: 6.2, max: 2730.8),
                WeightedCredentialVarianceLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
