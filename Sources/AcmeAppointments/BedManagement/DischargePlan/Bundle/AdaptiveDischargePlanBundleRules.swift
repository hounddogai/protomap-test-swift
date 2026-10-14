import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive discharge plan bundle must pass. Check returns its problems, or none.
    protocol AdaptiveDischargePlanBundleRule {
        func check(_ item: AdaptiveDischargePlanBundle) -> [String]
    }

    final class AdaptiveDischargePlanBundleRefillsRangeRule: AdaptiveDischargePlanBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveDischargePlanBundle) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveDischargePlanBundleWeightRangeRule: AdaptiveDischargePlanBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveDischargePlanBundle) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveDischargePlanBundleEncounterIDLengthRule: AdaptiveDischargePlanBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDischargePlanBundle) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive discharge plan bundle.
    final class AdaptiveDischargePlanBundleValidator {
        var rules: [any AdaptiveDischargePlanBundleRule]

        init(rules: [any AdaptiveDischargePlanBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveDischargePlanBundle) -> [String] {
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

        func requireValid(_ item: AdaptiveDischargePlanBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveDischargePlanBundle]) -> [String: [String]] {
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

    static func defaultAdaptiveDischargePlanBundleValidator() -> AdaptiveDischargePlanBundleValidator {
        return AdaptiveDischargePlanBundleValidator(
            rules: [
                AdaptiveDischargePlanBundleRefillsRangeRule(min: 120, max: 3600),
                AdaptiveDischargePlanBundleWeightRangeRule(min: 4.9, max: 3076.9),
                AdaptiveDischargePlanBundleEncounterIDLengthRule(maxLength: 1000),
            ]
        )
    }
}
