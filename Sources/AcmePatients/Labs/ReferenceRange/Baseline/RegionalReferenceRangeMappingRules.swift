import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional reference range mapping must pass. Check returns its problems, or none.
    protocol RegionalReferenceRangeMappingRule {
        func check(_ item: RegionalReferenceRangeMapping) -> [String]
    }

    final class RegionalReferenceRangeMappingAcuityRangeRule: RegionalReferenceRangeMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalReferenceRangeMapping) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalReferenceRangeMappingCodePrefixRule: RegionalReferenceRangeMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalReferenceRangeMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalReferenceRangeMappingThresholdRangeRule: RegionalReferenceRangeMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalReferenceRangeMapping) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalReferenceRangeMappingRequiredNameRule: RegionalReferenceRangeMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalReferenceRangeMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional reference range mapping.
    final class RegionalReferenceRangeMappingValidator {
        var rules: [any RegionalReferenceRangeMappingRule]

        init(rules: [any RegionalReferenceRangeMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalReferenceRangeMapping) -> [String] {
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

        func requireValid(_ item: RegionalReferenceRangeMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalReferenceRangeMapping]) -> [String: [String]] {
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

    static func defaultRegionalReferenceRangeMappingValidator() -> RegionalReferenceRangeMappingValidator {
        return RegionalReferenceRangeMappingValidator(
            rules: [
                RegionalReferenceRangeMappingAcuityRangeRule(min: 120, max: 1000),
                RegionalReferenceRangeMappingCodePrefixRule(prefix: "OPS"),
                RegionalReferenceRangeMappingThresholdRangeRule(min: 2.1, max: 2892.6),
                RegionalReferenceRangeMappingRequiredNameRule(
                    message: "regional reference range mapping needs a value"
                ),
            ]
        )
    }
}
