import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality baseline must pass. Check returns its problems, or none.
    protocol ModalityBaselineRule {
        func check(_ item: ModalityBaseline) -> [String]
    }

    final class ModalityBaselineLimitRangeRule: ModalityBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityBaseline) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityBaselineLabelLengthRule: ModalityBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityBaselineWeightRangeRule: ModalityBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityBaseline) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality baseline.
    final class ModalityBaselineValidator {
        var rules: [any ModalityBaselineRule]

        init(rules: [any ModalityBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityBaseline]) -> [String: [String]] {
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

    static func defaultModalityBaselineValidator() -> ModalityBaselineValidator {
        return ModalityBaselineValidator(
            rules: [
                ModalityBaselineLimitRangeRule(min: 64, max: 120),
                ModalityBaselineLabelLengthRule(maxLength: 80),
                ModalityBaselineWeightRangeRule(min: 4.1, max: 4247.7),
            ]
        )
    }
}
