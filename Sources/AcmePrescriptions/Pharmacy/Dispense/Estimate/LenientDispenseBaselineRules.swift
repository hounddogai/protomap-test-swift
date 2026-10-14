import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient dispense baseline must pass. Check returns its problems, or none.
    protocol LenientDispenseBaselineRule {
        func check(_ item: LenientDispenseBaseline) -> [String]
    }

    final class LenientDispenseBaselineRequiredLabelRule: LenientDispenseBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDispenseBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDispenseBaselineAllowedLabelRule: LenientDispenseBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientDispenseBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    final class LenientDispenseBaselineCeilingRangeRule: LenientDispenseBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientDispenseBaseline) -> [String] {
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

    /// Runs every rule of a lenient dispense baseline.
    final class LenientDispenseBaselineValidator {
        var rules: [any LenientDispenseBaselineRule]

        init(rules: [any LenientDispenseBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientDispenseBaseline) -> [String] {
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

        func requireValid(_ item: LenientDispenseBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientDispenseBaseline]) -> [String: [String]] {
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

    static func defaultLenientDispenseBaselineValidator() -> LenientDispenseBaselineValidator {
        return LenientDispenseBaselineValidator(
            rules: [
                LenientDispenseBaselineRequiredLabelRule(message: "lenient dispense baseline needs this field"),
                LenientDispenseBaselineAllowedLabelRule(allowed: []),
                LenientDispenseBaselineCeilingRangeRule(min: 1.5, max: 3164.5),
            ]
        )
    }
}
