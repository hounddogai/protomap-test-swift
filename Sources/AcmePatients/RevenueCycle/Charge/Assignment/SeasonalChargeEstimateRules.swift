import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a seasonal charge estimate must pass. Check returns its problems, or none.
    protocol SeasonalChargeEstimateRule {
        func check(_ item: SeasonalChargeEstimate) -> [String]
    }

    final class SeasonalChargeEstimateCodeLengthRule: SeasonalChargeEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalChargeEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalChargeEstimateCostRangeRule: SeasonalChargeEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalChargeEstimate) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalChargeEstimateArchivedGuardRule: SeasonalChargeEstimateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SeasonalChargeEstimate) -> [String] {
            if item.archived && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class SeasonalChargeEstimateRequiredClinicianIDRule: SeasonalChargeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalChargeEstimate) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalChargeEstimateRequiredDiagnosisCodeRule: SeasonalChargeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalChargeEstimate) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal charge estimate.
    final class SeasonalChargeEstimateValidator {
        var rules: [any SeasonalChargeEstimateRule]

        init(rules: [any SeasonalChargeEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalChargeEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalChargeEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalChargeEstimate]) -> [String: [String]] {
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

    static func defaultSeasonalChargeEstimateValidator() -> SeasonalChargeEstimateValidator {
        return SeasonalChargeEstimateValidator(
            rules: [
                SeasonalChargeEstimateCodeLengthRule(maxLength: 3600),
                SeasonalChargeEstimateCostRangeRule(min: 0.9, max: 1780.7),
                SeasonalChargeEstimateArchivedGuardRule(limit: 64),
                SeasonalChargeEstimateRequiredClinicianIDRule(message: "seasonal charge estimate needs this field"),
                SeasonalChargeEstimateRequiredDiagnosisCodeRule(message: "seasonal charge estimate needs a value"),
            ]
        )
    }
}
