import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a weighted discharge plan estimate must pass. Check returns its problems, or none.
    protocol WeightedDischargePlanEstimateRule {
        func check(_ item: WeightedDischargePlanEstimate) -> [String]
    }

    final class WeightedDischargePlanEstimateRequiredClinicianIDRule: WeightedDischargePlanEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedDischargePlanEstimate) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedDischargePlanEstimateLabelLengthRule: WeightedDischargePlanEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedDischargePlanEstimate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedDischargePlanEstimateCodeLengthRule: WeightedDischargePlanEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedDischargePlanEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedDischargePlanEstimateRequiredLabelRule: WeightedDischargePlanEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedDischargePlanEstimate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted discharge plan estimate.
    final class WeightedDischargePlanEstimateValidator {
        var rules: [any WeightedDischargePlanEstimateRule]

        init(rules: [any WeightedDischargePlanEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedDischargePlanEstimate) -> [String] {
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

        func requireValid(_ item: WeightedDischargePlanEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedDischargePlanEstimate]) -> [String: [String]] {
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

    static func defaultWeightedDischargePlanEstimateValidator() -> WeightedDischargePlanEstimateValidator {
        return WeightedDischargePlanEstimateValidator(
            rules: [
                WeightedDischargePlanEstimateRequiredClinicianIDRule(
                    message: "weighted discharge plan estimate needs an entry"
                ),
                WeightedDischargePlanEstimateLabelLengthRule(maxLength: 255),
                WeightedDischargePlanEstimateCodeLengthRule(maxLength: 32),
                WeightedDischargePlanEstimateRequiredLabelRule(
                    message: "weighted discharge plan estimate needs an entry"
                ),
            ]
        )
    }
}
