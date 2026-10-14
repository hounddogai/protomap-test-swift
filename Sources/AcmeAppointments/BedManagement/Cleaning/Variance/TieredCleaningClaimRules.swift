import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a tiered cleaning claim must pass. Check returns its problems, or none.
    protocol TieredCleaningClaimRule {
        func check(_ item: TieredCleaningClaim) -> [String]
    }

    final class TieredCleaningClaimRequiredLabelRule: TieredCleaningClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCleaningClaim) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCleaningClaimLabelLengthRule: TieredCleaningClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCleaningClaim) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCleaningClaimRatioRangeRule: TieredCleaningClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCleaningClaim) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredCleaningClaimAllowedPatientRefRule: TieredCleaningClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredCleaningClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is unknown"]
            }
            return []
        }
    }

    final class TieredCleaningClaimPatientRefLengthRule: TieredCleaningClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCleaningClaim) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered cleaning claim.
    final class TieredCleaningClaimValidator {
        var rules: [any TieredCleaningClaimRule]

        init(rules: [any TieredCleaningClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCleaningClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredCleaningClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCleaningClaim]) -> [String: [String]] {
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

    static func defaultTieredCleaningClaimValidator() -> TieredCleaningClaimValidator {
        return TieredCleaningClaimValidator(
            rules: [
                TieredCleaningClaimRequiredLabelRule(message: "tiered cleaning claim needs a value"),
                TieredCleaningClaimLabelLengthRule(maxLength: 3600),
                TieredCleaningClaimRatioRangeRule(min: 1.2, max: 4176.1),
                TieredCleaningClaimAllowedPatientRefRule(allowed: ["regional"]),
                TieredCleaningClaimPatientRefLengthRule(maxLength: 86400),
            ]
        )
    }
}
