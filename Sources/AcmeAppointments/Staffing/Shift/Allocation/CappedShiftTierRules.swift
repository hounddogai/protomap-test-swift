import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped shift tier must pass. Check returns its problems, or none.
    protocol CappedShiftTierRule {
        func check(_ item: CappedShiftTier) -> [String]
    }

    final class CappedShiftTierFacilityLengthRule: CappedShiftTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedShiftTier) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedShiftTierCopayRangeRule: CappedShiftTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedShiftTier) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedShiftTierRequiredFacilityRule: CappedShiftTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedShiftTier) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedShiftTierRequiredPatientRefRule: CappedShiftTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedShiftTier) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedShiftTierCeilingRangeRule: CappedShiftTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedShiftTier) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped shift tier.
    final class CappedShiftTierValidator {
        var rules: [any CappedShiftTierRule]

        init(rules: [any CappedShiftTierRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedShiftTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedShiftTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedShiftTier]) -> [String: [String]] {
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

    static func defaultCappedShiftTierValidator() -> CappedShiftTierValidator {
        return CappedShiftTierValidator(
            rules: [
                CappedShiftTierFacilityLengthRule(maxLength: 64),
                CappedShiftTierCopayRangeRule(min: 3.8, max: 2028.9),
                CappedShiftTierRequiredFacilityRule(message: "capped shift tier needs an entry"),
                CappedShiftTierRequiredPatientRefRule(message: "capped shift tier needs an entry"),
                CappedShiftTierCeilingRangeRule(min: 6.4, max: 980.7),
            ]
        )
    }
}
