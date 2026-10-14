import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global read variance must pass. Check returns its problems, or none.
    protocol GlobalReadVarianceRule {
        func check(_ item: GlobalReadVariance) -> [String]
    }

    final class GlobalReadVarianceLabelLengthRule: GlobalReadVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReadVariance) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalReadVarianceContactEmailLengthRule: GlobalReadVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReadVariance) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalReadVarianceRequiredContactEmailRule: GlobalReadVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReadVariance) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReadVarianceChecksumLengthRule: GlobalReadVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReadVariance) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalReadVarianceBudgetRangeRule: GlobalReadVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReadVariance) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalReadVarianceWeightRangeRule: GlobalReadVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReadVariance) -> [String] {
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

    /// Runs every rule of a global read variance.
    final class GlobalReadVarianceValidator {
        var rules: [any GlobalReadVarianceRule]

        init(rules: [any GlobalReadVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalReadVariance) -> [String] {
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

        func requireValid(_ item: GlobalReadVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalReadVariance]) -> [String: [String]] {
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

    static func defaultGlobalReadVarianceValidator() -> GlobalReadVarianceValidator {
        return GlobalReadVarianceValidator(
            rules: [
                GlobalReadVarianceLabelLengthRule(maxLength: 120),
                GlobalReadVarianceContactEmailLengthRule(maxLength: 32),
                GlobalReadVarianceRequiredContactEmailRule(message: "global read variance needs this field"),
                GlobalReadVarianceChecksumLengthRule(maxLength: 32),
                GlobalReadVarianceBudgetRangeRule(min: 7.6, max: 4860.8),
                GlobalReadVarianceWeightRangeRule(min: 2.6, max: 334.7),
            ]
        )
    }
}
