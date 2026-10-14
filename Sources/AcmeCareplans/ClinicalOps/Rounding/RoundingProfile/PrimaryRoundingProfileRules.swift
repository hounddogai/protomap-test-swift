import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary rounding profile must pass. Check returns its problems, or none.
    protocol PrimaryRoundingProfileRule {
        func check(_ item: PrimaryRoundingProfile) -> [String]
    }

    final class PrimaryRoundingProfilePatientRefLengthRule: PrimaryRoundingProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRoundingProfile) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRoundingProfileDiscountRangeRule: PrimaryRoundingProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRoundingProfile) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryRoundingProfileCodePrefixRule: PrimaryRoundingProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryRoundingProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryRoundingProfileCodeLengthRule: PrimaryRoundingProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRoundingProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRoundingProfileRetriesRangeRule: PrimaryRoundingProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRoundingProfile) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary rounding profile.
    final class PrimaryRoundingProfileValidator {
        var rules: [any PrimaryRoundingProfileRule]

        init(rules: [any PrimaryRoundingProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryRoundingProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryRoundingProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryRoundingProfile]) -> [String: [String]] {
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

    static func defaultPrimaryRoundingProfileValidator() -> PrimaryRoundingProfileValidator {
        return PrimaryRoundingProfileValidator(
            rules: [
                PrimaryRoundingProfilePatientRefLengthRule(maxLength: 32),
                PrimaryRoundingProfileDiscountRangeRule(min: 3.7, max: 4912.8),
                PrimaryRoundingProfileCodePrefixRule(prefix: "OPS"),
                PrimaryRoundingProfileCodeLengthRule(maxLength: 86400),
                PrimaryRoundingProfileRetriesRangeRule(min: 64, max: 120),
            ]
        )
    }
}
