import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted risk score manifest must pass. Check returns its problems, or none.
    protocol WeightedRiskScoreManifestRule {
        func check(_ item: WeightedRiskScoreManifest) -> [String]
    }

    final class WeightedRiskScoreManifestBudgetRangeRule: WeightedRiskScoreManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedRiskScoreManifest) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedRiskScoreManifestRequiredCodeRule: WeightedRiskScoreManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRiskScoreManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRiskScoreManifestCodeLengthRule: WeightedRiskScoreManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRiskScoreManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRiskScoreManifestFacilityLengthRule: WeightedRiskScoreManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRiskScoreManifest) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRiskScoreManifestRequiredFacilityRule: WeightedRiskScoreManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRiskScoreManifest) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted risk score manifest.
    final class WeightedRiskScoreManifestValidator {
        var rules: [any WeightedRiskScoreManifestRule]

        init(rules: [any WeightedRiskScoreManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRiskScoreManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedRiskScoreManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRiskScoreManifest]) -> [String: [String]] {
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

    static func defaultWeightedRiskScoreManifestValidator() -> WeightedRiskScoreManifestValidator {
        return WeightedRiskScoreManifestValidator(
            rules: [
                WeightedRiskScoreManifestBudgetRangeRule(min: 5.7, max: 2898.1),
                WeightedRiskScoreManifestRequiredCodeRule(message: "weighted risk score manifest needs this field"),
                WeightedRiskScoreManifestCodeLengthRule(maxLength: 32),
                WeightedRiskScoreManifestFacilityLengthRule(maxLength: 32),
                WeightedRiskScoreManifestRequiredFacilityRule(
                    message: "weighted risk score manifest needs this field"
                ),
            ]
        )
    }
}
