import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted program claim must pass. Check returns its problems, or none.
    protocol WeightedProgramClaimRule {
        func check(_ item: WeightedProgramClaim) -> [String]
    }

    final class WeightedProgramClaimRequiredLabelRule: WeightedProgramClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedProgramClaim) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedProgramClaimReviewerLengthRule: WeightedProgramClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedProgramClaim) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedProgramClaimExternalRefLengthRule: WeightedProgramClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedProgramClaim) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedProgramClaimRequiredExternalRefRule: WeightedProgramClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedProgramClaim) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedProgramClaimDiscountRangeRule: WeightedProgramClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedProgramClaim) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted program claim.
    final class WeightedProgramClaimValidator {
        var rules: [any WeightedProgramClaimRule]

        init(rules: [any WeightedProgramClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedProgramClaim) -> [String] {
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

        func requireValid(_ item: WeightedProgramClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedProgramClaim]) -> [String: [String]] {
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

    static func defaultWeightedProgramClaimValidator() -> WeightedProgramClaimValidator {
        return WeightedProgramClaimValidator(
            rules: [
                WeightedProgramClaimRequiredLabelRule(message: "weighted program claim needs this field"),
                WeightedProgramClaimReviewerLengthRule(maxLength: 1000),
                WeightedProgramClaimExternalRefLengthRule(maxLength: 255),
                WeightedProgramClaimRequiredExternalRefRule(message: "weighted program claim needs this field"),
                WeightedProgramClaimDiscountRangeRule(min: 9.2, max: 2473.0),
            ]
        )
    }
}
