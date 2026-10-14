import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range mapping must pass. Check returns its problems, or none.
    protocol ReferenceRangeMappingRule {
        func check(_ item: ReferenceRangeMapping) -> [String]
    }

    final class ReferenceRangeMappingAllowedNameRule: ReferenceRangeMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class ReferenceRangeMappingNameLengthRule: ReferenceRangeMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeMappingRatioRangeRule: ReferenceRangeMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeMapping) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range mapping.
    final class ReferenceRangeMappingValidator {
        var rules: [any ReferenceRangeMappingRule]

        init(rules: [any ReferenceRangeMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeMapping) -> [String] {
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

        func requireValid(_ item: ReferenceRangeMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeMapping]) -> [String: [String]] {
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

    static func defaultReferenceRangeMappingValidator() -> ReferenceRangeMappingValidator {
        return ReferenceRangeMappingValidator(
            rules: [
                ReferenceRangeMappingAllowedNameRule(allowed: ["legacy"]),
                ReferenceRangeMappingNameLengthRule(maxLength: 120),
                ReferenceRangeMappingRatioRangeRule(min: 6.9, max: 1615.9),
            ]
        )
    }
}
